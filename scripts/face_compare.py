#!/usr/bin/env python3
"""
Face comparison utility for Shadow Sentinel — Neural Camera System.
Detects faces in two images and computes a similarity score.

Requires: opencv-python, numpy
Install : pip install opencv-python numpy

Usage:
  python face_compare.py <reference_image> <current_image>

Output (JSON):
  {
    "match": true/false,
    "confidence": 0.0–100.0,
    "liveness": 0.0–100.0,
    "faces_detected_ref": int,
    "faces_detected_cur": int,
    "error": null or "message"
  }
"""

import sys
import json
import os
import numpy as np

try:
    import cv2
except ImportError:
    print(json.dumps({
        "match": False,
        "confidence": 0.0,
        "liveness": 0.0,
        "faces_detected_ref": 0,
        "faces_detected_cur": 0,
        "error": "opencv-python not installed. Run: pip install opencv-python numpy"
    }))
    sys.exit(1)


def detect_face(image, cascade):
    """Detect the largest face in the image and return the cropped face region."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(80, 80),
        flags=cv2.CASCADE_SCALE_IMAGE,
    )
    if len(faces) == 0:
        return None, 0, gray

    # Pick the largest face
    areas = [w * h for (x, y, w, h) in faces]
    idx = np.argmax(areas)
    (x, y, w, h) = faces[idx]

    # Expand region slightly for better comparison (20% padding)
    pad = int(0.2 * max(w, h))
    y1 = max(0, y - pad)
    y2 = min(gray.shape[0], y + h + pad)
    x1 = max(0, x - pad)
    x2 = min(gray.shape[1], x + w + pad)

    face_roi = gray[y1:y2, x1:x2]
    return face_roi, len(faces), gray


def compute_similarity(face1, face2):
    """Compute similarity between two face ROIs using multiple methods."""
    # Resize both to a canonical size
    size = (128, 128)
    f1 = cv2.resize(face1, size)
    f2 = cv2.resize(face2, size)

    # Method 1: Histogram correlation
    hist1 = cv2.calcHist([f1], [0], None, [256], [0, 256])
    hist2 = cv2.calcHist([f2], [0], None, [256], [0, 256])
    cv2.normalize(hist1, hist1)
    cv2.normalize(hist2, hist2)
    hist_corr = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)  # -1 to 1

    # Method 2: Structural similarity (SSIM-like via normalized correlation)
    f1_f = f1.astype(np.float64)
    f2_f = f2.astype(np.float64)
    mean1 = np.mean(f1_f)
    mean2 = np.mean(f2_f)
    std1 = np.std(f1_f)
    std2 = np.std(f2_f)

    if std1 < 1e-6 or std2 < 1e-6:
        ncc = 0.0
    else:
        ncc = np.mean((f1_f - mean1) * (f2_f - mean2)) / (std1 * std2)

    # Method 3: Absolute difference-based score
    diff = cv2.absdiff(f1, f2)
    diff_score = 1.0 - (np.mean(diff) / 255.0)

    # Weighted combination
    similarity = (hist_corr * 0.30) + (ncc * 0.45) + (diff_score * 0.25)

    # Clamp to [0, 1]
    similarity = max(0.0, min(1.0, similarity))
    return similarity


def estimate_liveness(image, face_roi):
    """
    Basic liveness estimation using:
    - Laplacian variance (blur detection — photos tend to be sharper/flatter)
    - Face-to-image ratio (real faces fill a natural portion of the frame)
    - Edge density in the face region
    """
    if face_roi is None:
        return 50.0

    # Laplacian variance — higher = more texture = more likely real
    laplacian_var = cv2.Laplacian(face_roi, cv2.CV_64F).var()
    # Typical range: 50–2000 for real faces, <50 for smooth printed photos
    lap_score = min(1.0, laplacian_var / 800.0)

    # Edge density
    edges = cv2.Canny(face_roi, 50, 150)
    edge_density = np.count_nonzero(edges) / edges.size
    # Real faces typically: 0.05–0.20
    edge_score = min(1.0, edge_density / 0.12)

    # Combine
    liveness = (lap_score * 0.6 + edge_score * 0.4) * 100.0
    return max(0.0, min(100.0, liveness))


def main():
    if len(sys.argv) < 3:
        print(json.dumps({
            "match": False,
            "confidence": 0.0,
            "liveness": 0.0,
            "faces_detected_ref": 0,
            "faces_detected_cur": 0,
            "error": "Usage: python face_compare.py <reference> <current>"
        }))
        sys.exit(1)

    ref_path = sys.argv[1]
    cur_path = sys.argv[2]

    # Validate files exist
    for p in [ref_path, cur_path]:
        if not os.path.isfile(p):
            print(json.dumps({
                "match": False,
                "confidence": 0.0,
                "liveness": 0.0,
                "faces_detected_ref": 0,
                "faces_detected_cur": 0,
                "error": f"File not found: {p}"
            }))
            sys.exit(1)

    # Load Haar cascade
    cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    cascade = cv2.CascadeClassifier(cascade_path)

    if cascade.empty():
        print(json.dumps({
            "match": False,
            "confidence": 0.0,
            "liveness": 0.0,
            "faces_detected_ref": 0,
            "faces_detected_cur": 0,
            "error": "Failed to load Haar cascade classifier"
        }))
        sys.exit(1)

    # Load images
    ref_img = cv2.imread(ref_path)
    cur_img = cv2.imread(cur_path)

    if ref_img is None or cur_img is None:
        print(json.dumps({
            "match": False,
            "confidence": 0.0,
            "liveness": 0.0,
            "faces_detected_ref": 0,
            "faces_detected_cur": 0,
            "error": "Failed to read one or both images"
        }))
        sys.exit(1)

    # Detect faces
    ref_face, ref_count, ref_gray = detect_face(ref_img, cascade)
    cur_face, cur_count, cur_gray = detect_face(cur_img, cascade)

    if ref_face is None:
        print(json.dumps({
            "match": False,
            "confidence": 0.0,
            "liveness": 0.0,
            "faces_detected_ref": 0,
            "faces_detected_cur": cur_count,
            "error": "No face detected in reference image"
        }))
        sys.exit(0)

    if cur_face is None:
        print(json.dumps({
            "match": False,
            "confidence": 0.0,
            "liveness": 0.0,
            "faces_detected_ref": ref_count,
            "faces_detected_cur": 0,
            "error": "No face detected in current image"
        }))
        sys.exit(0)

    # Compare faces
    similarity = compute_similarity(ref_face, cur_face)
    confidence = float(similarity * 100.0)

    # Estimate liveness on current image
    liveness = float(estimate_liveness(cur_img, cur_face))

    # Match threshold: 55% similarity (allows for lighting/angle changes)
    is_match = confidence >= 55.0

    result = {
        "match": bool(is_match),
        "confidence": round(confidence, 2),
        "liveness": round(liveness, 2),
        "faces_detected_ref": int(ref_count),
        "faces_detected_cur": int(cur_count),
        "error": None,
    }

    print(json.dumps(result))
    sys.exit(0)


if __name__ == "__main__":
    main()
