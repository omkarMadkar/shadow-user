#!/usr/bin/env python3
"""
mongo_upload.py — Shadow Sentinel capture evidence uploader.

Uploads a detection event (keystroke alert or face mismatch) to MongoDB Atlas.
Screenshots and face photos are stored in GridFS; metadata in detection_events.

Usage:
    python mongo_upload.py \
        --event_type keystroke_alert \
        --user_email user@example.com \
        --alert_type threat \
        --severity severe \
        --flagged_words "kill,murder" \
        --transcript "I will kill you" \
        --screenshot_path /abs/path/screen.png \
        --face_path /abs/path/face.jpg \
        --verified true \
        --confidence 87.5

Prints JSON to stdout: {"ok": true, "id": "<docId>"} or {"ok": false, "error": "..."}

Requirements:
    pip install pymongo python-dotenv
"""

import argparse
import json
import os
import sys
import traceback
from datetime import datetime, timezone

# ── Env / URI ──────────────────────────────────────────────────
def _load_uri():
    """Load MongoDB URI from .env file next to this script, or from env var."""
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('MONGO_URI=') and not line.startswith('#'):
                    return line[len('MONGO_URI='):].strip().strip('"').strip("'")
    return os.environ.get('MONGO_URI', '')


def _load_db_name():
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('MONGO_DB=') and not line.startswith('#'):
                    return line[len('MONGO_DB='):].strip().strip('"').strip("'")
    return os.environ.get('MONGO_DB', 'shadow_sentinel')


# ── GridFS upload ──────────────────────────────────────────────
def _upload_file_to_gridfs(fs, file_path: str, meta: dict) -> str | None:
    """Read file from disk and store in GridFS. Returns the file_id string."""
    if not file_path or not os.path.exists(file_path):
        return None
    try:
        with open(file_path, 'rb') as f:
            data = f.read()
        file_id = fs.put(data, filename=os.path.basename(file_path), **meta)
        return str(file_id)
    except Exception as e:
        print(f'[GridFS] Failed to upload {file_path}: {e}', file=sys.stderr)
        return None


# ── Main ───────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description='Upload detection event to MongoDB Atlas')
    parser.add_argument('--event_type', required=True, help='keystroke_alert | face_alert')
    parser.add_argument('--user_email', required=True)
    parser.add_argument('--alert_type', default='')
    parser.add_argument('--severity', default='')
    parser.add_argument('--flagged_words', default='')
    parser.add_argument('--transcript', default='')
    parser.add_argument('--screenshot_path', default='')
    parser.add_argument('--face_path', default='')
    parser.add_argument('--verified', default='', help='true | false | unknown')
    parser.add_argument('--confidence', default='0', type=float)
    parser.add_argument('--consecutive_mismatches', default='0', type=int)
    args = parser.parse_args()

    uri = _load_uri()
    db_name = _load_db_name()

    if not uri:
        result = {'ok': False, 'error': 'MONGO_URI not set. Edit scripts/.env'}
        print(json.dumps(result))
        sys.exit(1)

    try:
        import pymongo
        import gridfs
    except ImportError:
        result = {'ok': False, 'error': 'pymongo not installed. Run: pip install pymongo python-dotenv'}
        print(json.dumps(result))
        sys.exit(1)

    try:
        client = pymongo.MongoClient(uri, serverSelectionTimeoutMS=8000)
        # Force connection test
        client.admin.command('ping')

        db = client[db_name]
        fs = gridfs.GridFS(db)
        collection = db['detection_events']

        now = datetime.now(timezone.utc)

        # ── Upload images to GridFS ──
        img_meta = {
            'user_email': args.user_email,
            'event_type': args.event_type,
            'uploaded_at': now,
        }

        screenshot_gridfs_id = _upload_file_to_gridfs(
            fs, args.screenshot_path, {**img_meta, 'image_type': 'screenshot'}
        )
        face_gridfs_id = _upload_file_to_gridfs(
            fs, args.face_path, {**img_meta, 'image_type': 'face_photo'}
        )

        # ── Build document ──
        flagged_list = [w.strip() for w in args.flagged_words.split(',') if w.strip()]

        verified_val = None
        if args.verified.lower() == 'true':
            verified_val = True
        elif args.verified.lower() == 'false':
            verified_val = False

        doc = {
            'event_type': args.event_type,          # keystroke_alert | face_alert
            'user_email': args.user_email,
            'alert_type': args.alert_type,
            'severity': args.severity,
            'flagged_words': flagged_list,
            'transcript': args.transcript,
            'face_verified': verified_val,           # None = not checked, True/False
            'face_confidence': args.confidence,
            'consecutive_mismatches': args.consecutive_mismatches,
            'screenshot_path': args.screenshot_path or None,
            'face_path': args.face_path or None,
            'screenshot_gridfs_id': screenshot_gridfs_id,
            'face_gridfs_id': face_gridfs_id,
            'created_at': now,
            'created_at_local': datetime.now().isoformat(),
        }

        insert_result = collection.insert_one(doc)
        doc_id = str(insert_result.inserted_id)

        print(json.dumps({'ok': True, 'id': doc_id}))
        client.close()

    except Exception as e:
        tb = traceback.format_exc()
        print(f'[MongoUpload] Error:\n{tb}', file=sys.stderr)
        print(json.dumps({'ok': False, 'error': str(e)}))
        sys.exit(1)


if __name__ == '__main__':
    main()
