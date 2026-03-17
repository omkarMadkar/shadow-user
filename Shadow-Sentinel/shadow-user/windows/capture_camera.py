#!/usr/bin/env python3
"""
Simple camera capture utility for Windows
Requires: opencv-python
Install: pip install opencv-python
"""

import sys
import cv2
import os

def capture_camera(output_path):
    """Capture a frame from the default camera and save as JPEG"""
    try:
        # Open default camera (0 = first camera device)
        cap = cv2.VideoCapture(0)
        
        if not cap.isOpened():
            print("ERROR: Cannot open camera device")
            return False
        
        # Read a frame
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            print("ERROR: Failed to read frame from camera")
            return False
        
        # Create output directory if needed
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Save frame as JPEG
        success = cv2.imwrite(output_path, frame)
        
        if success:
            print(f"SUCCESS: Camera photo saved to {output_path}")
            return True
        else:
            print("ERROR: Failed to save image")
            return False
            
    except Exception as e:
        print(f"ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python capture_camera.py <output_path>")
        sys.exit(1)
    
    output_path = sys.argv[1]
    success = capture_camera(output_path)
    sys.exit(0 if success else 1)
