"""
Shadow Sentinel Backend — FastAPI REST Server

Provides AI-powered continuous authentication endpoints:
  - /api/face/verify      — Face verification with confidence scoring
  - /api/keystroke/analyze — Keystroke dynamics anomaly detection
  - /api/threat/detect    — Activity threat analysis
  - /api/trust/score      — Unified trust score calculation

Run: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import logging
from datetime import datetime
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Import route modules
from routes import face, keystroke, threat, content

# ─── Logging Setup ────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("sentinel")


# ─── Lifespan Context Manager ─────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    logger.info("=" * 60)
    logger.info("  SHADOW SENTINEL BACKEND STARTING")
    logger.info("  Zero Trust Continuous Authentication API")
    logger.info("=" * 60)
    logger.info("Endpoints:")
    logger.info("  POST /api/face/verify        — Face verification")
    logger.info("  POST /api/face/enroll        — Face enrollment")
    logger.info("  POST /api/keystroke/analyze  — Keystroke analysis")
    logger.info("  POST /api/keystroke/enroll   — Keystroke enrollment")
    logger.info("  POST /api/threat/detect      — Threat detection")
    logger.info("  POST /api/content/analyze    — Content threat analysis")
    logger.info("  POST /api/trust/score        — Trust score calculation")
    logger.info("  GET  /health                 — Health check")
    logger.info("=" * 60)
    yield
    logger.info("Shadow Sentinel Backend shutting down...")


# ─── FastAPI App ──────────────────────────────────────────────
app = FastAPI(
    title="Shadow Sentinel API",
    description="AI-powered Continuous Authentication & Insider Threat Detection",
    version="1.0.0",
    lifespan=lifespan,
)


# ─── CORS Middleware ──────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for hackathon demo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Request Logging Middleware ───────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests."""
    start = datetime.now()
    response = await call_next(request)
    duration = (datetime.now() - start).total_seconds() * 1000
    
    # Skip logging for health checks to reduce noise
    if request.url.path != "/health":
        logger.info(
            f"{request.method} {request.url.path} → {response.status_code} "
            f"({duration:.1f}ms)"
        )
    
    return response


# ─── Exception Handler ────────────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all exception handler."""
    logger.error(f"Unhandled error: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": str(exc),
            "message": "Internal server error",
        },
    )


# ─── Health Check ─────────────────────────────────────────────
@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "service": "shadow-sentinel-api",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "modules": {
            "face_verification": "online",
            "keystroke_analysis": "online",
            "threat_detection": "online",
            "content_analysis": "online",
        },
    }


# ─── Root Endpoint ────────────────────────────────────────────
@app.get("/")
async def root():
    """API information."""
    return {
        "name": "Shadow Sentinel API",
        "description": "Zero Trust Continuous Authentication Platform",
        "version": "1.0.0",
        "endpoints": {
            "face_verify": "POST /api/face/verify",
            "face_enroll": "POST /api/face/enroll",
            "keystroke_analyze": "POST /api/keystroke/analyze",
            "keystroke_enroll": "POST /api/keystroke/enroll",
            "threat_detect": "POST /api/threat/detect",
            "content_analyze": "POST /api/content/analyze",
            "trust_score": "POST /api/trust/score",
            "health": "GET /health",
        },
    }


# ─── Include Route Modules ────────────────────────────────────
app.include_router(face.router, prefix="/api/face", tags=["Face Verification"])
app.include_router(keystroke.router, prefix="/api/keystroke", tags=["Keystroke Analysis"])
app.include_router(threat.router, prefix="/api/threat", tags=["Threat Detection"])
app.include_router(content.router, prefix="/api/content", tags=["Content Analysis"])


# ─── Trust Score Endpoint (Unified) ───────────────────────────
from pydantic import BaseModel
from typing import Optional


class TrustScoreRequest(BaseModel):
    """Request model for unified trust score calculation."""
    face_confidence: Optional[float] = None      # 0-100
    keystroke_match: Optional[float] = None      # 0-100
    activity_safety: Optional[float] = None      # 0-100
    
    # Weights (default: 40% face, 40% keystroke, 20% activity)
    face_weight: float = 0.40
    keystroke_weight: float = 0.40
    activity_weight: float = 0.20


class TrustScoreResponse(BaseModel):
    """Response model for trust score calculation."""
    success: bool
    trust_score: float
    components: dict
    risk_level: str
    recommendation: str


@app.post("/api/trust/score", response_model=TrustScoreResponse)
async def calculate_trust_score(request: TrustScoreRequest):
    """
    Calculate unified trust score using the formula:
    Trust = (weight_face × face_confidence) + 
            (weight_keystroke × keystroke_match) + 
            (weight_activity × activity_safety)
    """
    # Use defaults for missing values (assume baseline safe)
    face = request.face_confidence if request.face_confidence is not None else 85.0
    keystroke = request.keystroke_match if request.keystroke_match is not None else 80.0
    activity = request.activity_safety if request.activity_safety is not None else 90.0
    
    # Calculate weighted trust score
    trust_score = (
        request.face_weight * face +
        request.keystroke_weight * keystroke +
        request.activity_weight * activity
    )
    
    # Clamp to 0-100
    trust_score = max(0.0, min(100.0, trust_score))
    
    # Determine risk level
    if trust_score >= 80:
        risk_level = "LOW"
        recommendation = "User identity verified. Normal operation."
    elif trust_score >= 60:
        risk_level = "MEDIUM"
        recommendation = "Minor anomalies detected. Continue monitoring."
    elif trust_score >= 40:
        risk_level = "HIGH"
        recommendation = "Significant deviation. Recommend re-authentication."
    else:
        risk_level = "CRITICAL"
        recommendation = "Identity mismatch likely. Initiate lockdown protocol."
    
    return TrustScoreResponse(
        success=True,
        trust_score=round(trust_score, 2),
        components={
            "face_confidence": round(face, 2),
            "keystroke_match": round(keystroke, 2),
            "activity_safety": round(activity, 2),
            "weights": {
                "face": request.face_weight,
                "keystroke": request.keystroke_weight,
                "activity": request.activity_weight,
            },
        },
        risk_level=risk_level,
        recommendation=recommendation,
    )


# ─── Run Server ───────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
