"""
Face Verification API Routes

Endpoints:
  POST /api/face/verify  — Verify face against enrolled baseline
  POST /api/face/enroll  — Enroll a new face baseline

Supports:
  - Real OpenCV face detection when available
  - Simulation mode for demo reliability
  - Base64 image input
"""

import base64
import logging
import random
from datetime import datetime
from typing import Optional, List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

# Try to import OpenCV, fall back to simulation if unavailable
try:
    import cv2
    import numpy as np
    OPENCV_AVAILABLE = True
except ImportError:
    OPENCV_AVAILABLE = False

logger = logging.getLogger("sentinel.face")

router = APIRouter()


# ─── In-Memory Storage (Demo) ─────────────────────────────────
# In production, use a proper database with encrypted embeddings
_enrolled_faces = {}  # user_id -> embedding/histogram


# ─── Request/Response Models ──────────────────────────────────

class FaceVerifyRequest(BaseModel):
    """Request model for face verification."""
    user_id: str = Field(..., description="User identifier")
    image_base64: Optional[str] = Field(None, description="Base64 encoded face image")
    demo_mode: bool = Field(False, description="Use simulated verification")
    
    # Demo mode parameters for testing different scenarios
    simulate_match: Optional[bool] = Field(None, description="Force match/mismatch in demo")
    simulate_spoofing: bool = Field(False, description="Simulate spoofing attempt")


class FaceVerifyResponse(BaseModel):
    """Response model for face verification."""
    success: bool
    user_id: str
    matched: bool
    confidence: float = Field(..., ge=0, le=100)
    liveness_score: float = Field(..., ge=0, le=100)
    spoofing_detected: bool
    face_detected: bool
    scan_mode: str
    timestamp: str
    details: dict


class FaceEnrollRequest(BaseModel):
    """Request model for face enrollment."""
    user_id: str = Field(..., description="User identifier")
    image_base64: Optional[str] = Field(None, description="Base64 encoded face image")
    demo_mode: bool = Field(False, description="Use simulated enrollment")


class FaceEnrollResponse(BaseModel):
    """Response model for face enrollment."""
    success: bool
    user_id: str
    enrolled: bool
    message: str
    timestamp: str


# ─── Helper Functions ─────────────────────────────────────────

def decode_base64_image(base64_str: str) -> Optional[any]:
    """Decode base64 string to OpenCV image."""
    if not OPENCV_AVAILABLE:
        return None
    
    try:
        # Remove data URL prefix if present
        if "," in base64_str:
            base64_str = base64_str.split(",")[1]
        
        img_bytes = base64.b64decode(base64_str)
        nparr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return img
    except Exception as e:
        logger.error(f"Failed to decode image: {e}")
        return None


def detect_face_opencv(img) -> dict:
    """
    Detect face using OpenCV Haar Cascade.
    Returns face region and basic metrics.
    """
    if not OPENCV_AVAILABLE or img is None:
        return {"detected": False}
    
    try:
        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Load face cascade (ships with OpenCV)
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        )
        
        # Detect faces
        faces = face_cascade.detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(60, 60)
        )
        
        if len(faces) == 0:
            return {"detected": False}
        
        # Use the largest face
        x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
        face_region = gray[y:y+h, x:x+w]
        
        # Compute histogram as simple "embedding"
        hist = cv2.calcHist([face_region], [0], None, [256], [0, 256])
        hist = cv2.normalize(hist, hist).flatten()
        
        return {
            "detected": True,
            "bbox": [int(x), int(y), int(w), int(h)],
            "histogram": hist,
            "face_area": int(w * h),
            "image_size": img.shape[:2],
        }
    except Exception as e:
        logger.error(f"Face detection error: {e}")
        return {"detected": False}


def compare_histograms(hist1, hist2) -> float:
    """Compare two face histograms using correlation."""
    if hist1 is None or hist2 is None:
        return 0.0
    
    try:
        # OpenCV histogram comparison (correlation method)
        similarity = cv2.compareHist(
            hist1.astype(np.float32),
            hist2.astype(np.float32),
            cv2.HISTCMP_CORREL
        )
        # Convert to 0-100 confidence score
        # Correlation ranges from -1 to 1, map to 0-100
        confidence = (similarity + 1) * 50
        return max(0, min(100, confidence))
    except Exception as e:
        logger.error(f"Histogram comparison error: {e}")
        return 0.0


def simulate_verification(
    user_id: str,
    force_match: Optional[bool] = None,
    force_spoofing: bool = False,
) -> dict:
    """
    Generate realistic simulated face verification results.
    Used when OpenCV unavailable or demo_mode=True.
    """
    # Check if user is enrolled (in demo mode, assume enrolled)
    is_enrolled = user_id in _enrolled_faces or True
    
    # Determine match status
    if force_match is not None:
        matched = force_match
    else:
        # 85% chance of match for enrolled users
        matched = random.random() < 0.85 if is_enrolled else False
    
    # Generate confidence based on match status
    if matched:
        confidence = 85.0 + random.random() * 14.5  # 85-99.5%
    else:
        confidence = 15.0 + random.random() * 35.0  # 15-50%
    
    # Liveness score (high unless spoofing)
    if force_spoofing:
        liveness = 10.0 + random.random() * 25.0  # 10-35%
        spoofing = True
    else:
        liveness = 88.0 + random.random() * 11.5  # 88-99.5%
        spoofing = random.random() < 0.02  # 2% chance
    
    return {
        "matched": matched and not spoofing,
        "confidence": round(confidence, 2),
        "liveness_score": round(liveness, 2),
        "spoofing_detected": spoofing,
        "face_detected": True,
        "scan_mode": "SIMULATED",
    }


# ─── API Endpoints ────────────────────────────────────────────

@router.post("/verify", response_model=FaceVerifyResponse)
async def verify_face(request: FaceVerifyRequest):
    """
    Verify a face image against the enrolled baseline.
    
    - In demo_mode or when OpenCV unavailable: returns simulated results
    - With real image: performs actual face detection and comparison
    """
    user_id = request.user_id
    timestamp = datetime.now().isoformat()
    
    # Demo mode or simulation fallback
    if request.demo_mode or not OPENCV_AVAILABLE or not request.image_base64:
        logger.info(f"Face verify (demo): user={user_id}")
        
        sim = simulate_verification(
            user_id,
            force_match=request.simulate_match,
            force_spoofing=request.simulate_spoofing,
        )
        
        return FaceVerifyResponse(
            success=True,
            user_id=user_id,
            matched=sim["matched"],
            confidence=sim["confidence"],
            liveness_score=sim["liveness_score"],
            spoofing_detected=sim["spoofing_detected"],
            face_detected=sim["face_detected"],
            scan_mode=sim["scan_mode"],
            timestamp=timestamp,
            details={
                "mode": "demo" if request.demo_mode else "fallback",
                "opencv_available": OPENCV_AVAILABLE,
                "enrolled": user_id in _enrolled_faces,
            },
        )
    
    # Real face verification with OpenCV
    logger.info(f"Face verify (real): user={user_id}")
    
    # Decode image
    img = decode_base64_image(request.image_base64)
    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image data")
    
    # Detect face
    detection = detect_face_opencv(img)
    
    if not detection["detected"]:
        return FaceVerifyResponse(
            success=True,
            user_id=user_id,
            matched=False,
            confidence=0.0,
            liveness_score=0.0,
            spoofing_detected=False,
            face_detected=False,
            scan_mode="OPENCV",
            timestamp=timestamp,
            details={"error": "No face detected in image"},
        )
    
    # Compare with enrolled baseline
    enrolled_hist = _enrolled_faces.get(user_id)
    
    if enrolled_hist is None:
        # Not enrolled, but face detected
        confidence = 0.0
        matched = False
        details = {"error": "User not enrolled"}
    else:
        # Compare histograms
        confidence = compare_histograms(detection["histogram"], enrolled_hist)
        matched = confidence > 65.0  # Threshold for match
        details = {
            "comparison_method": "histogram_correlation",
            "face_area": detection["face_area"],
        }
    
    # Simple liveness heuristic (face size vs image size)
    h, w = detection["image_size"]
    face_ratio = detection["face_area"] / (h * w)
    liveness = 70.0 + (face_ratio * 100) if 0.05 < face_ratio < 0.6 else 30.0
    liveness = min(99.5, liveness + random.random() * 10)
    
    return FaceVerifyResponse(
        success=True,
        user_id=user_id,
        matched=matched,
        confidence=round(confidence, 2),
        liveness_score=round(liveness, 2),
        spoofing_detected=liveness < 50,
        face_detected=True,
        scan_mode="OPENCV",
        timestamp=timestamp,
        details=details,
    )


@router.post("/enroll", response_model=FaceEnrollResponse)
async def enroll_face(request: FaceEnrollRequest):
    """
    Enroll a new face baseline for a user.
    
    - In demo_mode: simulates enrollment
    - With real image: extracts and stores face histogram
    """
    user_id = request.user_id
    timestamp = datetime.now().isoformat()
    
    # Demo mode
    if request.demo_mode or not OPENCV_AVAILABLE or not request.image_base64:
        logger.info(f"Face enroll (demo): user={user_id}")
        _enrolled_faces[user_id] = "demo_embedding"
        
        return FaceEnrollResponse(
            success=True,
            user_id=user_id,
            enrolled=True,
            message="Face baseline enrolled successfully (demo mode)",
            timestamp=timestamp,
        )
    
    # Real enrollment with OpenCV
    logger.info(f"Face enroll (real): user={user_id}")
    
    img = decode_base64_image(request.image_base64)
    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image data")
    
    detection = detect_face_opencv(img)
    
    if not detection["detected"]:
        return FaceEnrollResponse(
            success=False,
            user_id=user_id,
            enrolled=False,
            message="No face detected in image. Please try again.",
            timestamp=timestamp,
        )
    
    # Store histogram as baseline
    _enrolled_faces[user_id] = detection["histogram"]
    
    return FaceEnrollResponse(
        success=True,
        user_id=user_id,
        enrolled=True,
        message="Face baseline enrolled successfully",
        timestamp=timestamp,
    )


@router.get("/status")
async def face_service_status():
    """Get face verification service status."""
    return {
        "service": "face_verification",
        "status": "online",
        "opencv_available": OPENCV_AVAILABLE,
        "enrolled_users": len(_enrolled_faces),
        "supported_modes": ["demo", "opencv"] if OPENCV_AVAILABLE else ["demo"],
    }
