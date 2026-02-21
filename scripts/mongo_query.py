#!/usr/bin/env python3
"""
mongo_query.py — Shadow Sentinel detection event fetcher.

Fetches detection events from MongoDB Atlas for a given user and prints JSON.

Usage:
    python mongo_query.py --user_email user@example.com [--limit 50]

Prints JSON array to stdout:
[
  {
    "id": "...",
    "event_type": "keystroke_alert",
    "user_email": "...",
    "alert_type": "threat",
    "severity": "severe",
    "flagged_words": ["kill"],
    "transcript": "...",
    "face_verified": true,
    "face_confidence": 87.5,
    "consecutive_mismatches": 0,
    "screenshot_path": "/abs/path/screen.png",
    "face_path": "/abs/path/face.jpg",
    "screenshot_gridfs_id": "...",
    "face_gridfs_id": "...",
    "created_at": "2026-02-21T13:30:00Z",
    "created_at_local": "2026-02-21T19:00:00"
  },
  ...
]

Requirements:
    pip install pymongo python-dotenv
"""

import argparse
import json
import os
import sys
import traceback


def _load_uri():
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


def main():
    parser = argparse.ArgumentParser(description='Query detection events from MongoDB Atlas')
    parser.add_argument('--user_email', required=True)
    parser.add_argument('--limit', default=100, type=int)
    parser.add_argument('--event_type', default='', help='Filter by event type (optional)')
    args = parser.parse_args()

    uri = _load_uri()
    db_name = _load_db_name()

    if not uri:
        print(json.dumps({'error': 'MONGO_URI not set. Edit scripts/.env'}))
        sys.exit(1)

    try:
        import pymongo
    except ImportError:
        print(json.dumps({'error': 'pymongo not installed. Run: pip install pymongo'}))
        sys.exit(1)

    try:
        client = pymongo.MongoClient(uri, serverSelectionTimeoutMS=8000)
        client.admin.command('ping')

        db = client[db_name]
        collection = db['detection_events']

        query = {'user_email': args.user_email}
        if args.event_type:
            query['event_type'] = args.event_type

        docs = list(
            collection.find(query)
            .sort('created_at', pymongo.DESCENDING)
            .limit(args.limit)
        )

        results = []
        for doc in docs:
            # Convert ObjectId and datetime to JSON-serialisable types
            created_at = doc.get('created_at')
            created_str = created_at.isoformat() if created_at else ''

            results.append({
                'id': str(doc['_id']),
                'event_type': doc.get('event_type', ''),
                'user_email': doc.get('user_email', ''),
                'alert_type': doc.get('alert_type', ''),
                'severity': doc.get('severity', ''),
                'flagged_words': doc.get('flagged_words', []),
                'transcript': doc.get('transcript', ''),
                'face_verified': doc.get('face_verified'),
                'face_confidence': doc.get('face_confidence', 0.0),
                'consecutive_mismatches': doc.get('consecutive_mismatches', 0),
                'screenshot_path': doc.get('screenshot_path') or '',
                'face_path': doc.get('face_path') or '',
                'screenshot_gridfs_id': doc.get('screenshot_gridfs_id') or '',
                'face_gridfs_id': doc.get('face_gridfs_id') or '',
                'created_at': created_str,
                'created_at_local': doc.get('created_at_local', ''),
            })

        print(json.dumps(results))
        client.close()

    except Exception as e:
        tb = traceback.format_exc()
        print(f'[MongoQuery] Error:\n{tb}', file=sys.stderr)
        print(json.dumps({'error': str(e)}))
        sys.exit(1)


if __name__ == '__main__':
    main()
