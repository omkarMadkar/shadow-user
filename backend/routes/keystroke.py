"""
Keystroke Dynamics Analysis API Routes

Endpoints:
  POST /api/keystroke/analyze — Analyze typing patterns for anomalies
  POST /api/keystroke/enroll  — Enroll typing baseline

Uses statistical analysis (Z-score) for anomaly detection.
Privacy-first: Only timing data processed, no key content.
"""

import logging
import math
import random
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel, Field

logger = logging.getLogger("sentinel.keystroke")

router = APIRouter()


# ─── In-Memory Storage (Demo) ─────────────────────────────────
# In production, use encrypted database storage
_enrolled_baselines = {}  # user_id -> baseline dict


# ─── Request/Response Models ──────────────────────────────────

class KeystrokeMetrics(BaseModel):
    """Typing metrics from a session."""
    dwell_times: List[float] = Field(default_factory=list, description="Key hold times in ms")
    flight_times: List[float] = Field(default_factory=list, description="Inter-key times in ms")
    wpm: Optional[float] = Field(None, description="Words per minute")
    key_count: int = Field(0, description="Total keys pressed")
    session_duration_ms: Optional[int] = Field(None, description="Session duration")


class KeystrokeAnalyzeRequest(BaseModel):
    """Request model for keystroke analysis."""
    user_id: str = Field(..., description="User identifier")
    metrics: KeystrokeMetrics = Field(..., description="Typing metrics to analyze")
    demo_mode: bool = Field(False, description="Use simulated analysis")
    
    # Demo mode parameters
    simulate_anomaly: Optional[float] = Field(None, description="Force specific anomaly score (0-1)")


class KeystrokeAnalyzeResponse(BaseModel):
    """Response model for keystroke analysis."""
    success: bool
    user_id: str
    anomaly_score: float = Field(..., ge=0, le=1, description="0=normal, 1=complete mismatch")
    match_score: float = Field(..., ge=0, le=100, description="Inverse of anomaly as percentage")
    risk_level: str
    metrics: dict
    deviations: dict
    recommendation: str
    timestamp: str


class KeystrokeEnrollRequest(BaseModel):
    """Request model for keystroke baseline enrollment."""
    user_id: str = Field(..., description="User identifier")
    metrics: KeystrokeMetrics = Field(..., description="Baseline typing metrics")
    demo_mode: bool = Field(False, description="Use simulated enrollment")


class KeystrokeEnrollResponse(BaseModel):
    """Response model for keystroke enrollment."""
    success: bool
    user_id: str
    enrolled: bool
    baseline: dict
    message: str
    timestamp: str


# ─── Statistical Helper Functions ─────────────────────────────

def compute_mean(values: List[float]) -> float:
    """Compute arithmetic mean."""
    if not values:
        return 0.0
    return sum(values) / len(values)


def compute_std(values: List[float], mean: Optional[float] = None) -> float:
    """Compute standard deviation."""
    if len(values) < 2:
        return 0.0
    if mean is None:
        mean = compute_mean(values)
    variance = sum((x - mean) ** 2 for x in values) / (len(values) - 1)
    return math.sqrt(variance)


def compute_z_score(value: float, mean: float, std: float) -> float:
    """Compute Z-score (standard deviations from mean)."""
    if std == 0:
        return 0.0
    return abs(value - mean) / std


def analyze_keystroke_metrics(
    current: KeystrokeMetrics,
    baseline: dict,
) -> dict:
    """
    Analyze current typing metrics against baseline using Z-scores.
    
    Returns anomaly analysis with component scores.
    """
    # Extract baseline stats
    b_dwell_mean = baseline.get("dwell_mean", 80)
    b_dwell_std = baseline.get("dwell_std", 15)
    b_flight_mean = baseline.get("flight_mean", 110)
    b_flight_std = baseline.get("flight_std", 22)
    b_wpm_mean = baseline.get("wpm_mean", 65)
    b_wpm_std = baseline.get("wpm_std", 10)
    
    # Compute current stats
    c_dwell_mean = compute_mean(current.dwell_times) if current.dwell_times else b_dwell_mean
    c_flight_mean = compute_mean(current.flight_times) if current.flight_times else b_flight_mean
    c_wpm = current.wpm if current.wpm else b_wpm_mean
    
    # Compute Z-scores for each component
    dwell_z = compute_z_score(c_dwell_mean, b_dwell_mean, b_dwell_std)
    flight_z = compute_z_score(c_flight_mean, b_flight_mean, b_flight_std)
    wpm_z = compute_z_score(c_wpm, b_wpm_mean, b_wpm_std)
    
    # Combined anomaly score (weighted average of Z-scores, normalized to 0-1)
    # Z > 3 is typically considered highly anomalous
    raw_score = (dwell_z * 0.4 + flight_z * 0.4 + wpm_z * 0.2)
    anomaly_score = min(1.0, raw_score / 3.0)  # Normalize: Z=3 → score=1.0
    
    return {
        "anomaly_score": round(anomaly_score, 4),
        "current_metrics": {
            "dwell_mean_ms": round(c_dwell_mean, 2),
            "flight_mean_ms": round(c_flight_mean, 2),
            "wpm": round(c_wpm, 2),
        },
        "baseline_metrics": {
            "dwell_mean_ms": b_dwell_mean,
            "dwell_std_ms": b_dwell_std,
            "flight_mean_ms": b_flight_mean,
            "flight_std_ms": b_flight_std,
            "wpm_mean": b_wpm_mean,
        },
        "z_scores": {
            "dwell": round(dwell_z, 3),
            "flight": round(flight_z, 3),
            "wpm": round(wpm_z, 3),
        },
    }


def simulate_analysis(
    user_id: str,
    force_anomaly: Optional[float] = None,
) -> dict:
    """
    Generate realistic simulated keystroke analysis.
    Used for demo mode or when baseline unavailable.
    """
    if force_anomaly is not None:
        anomaly_score = max(0.0, min(1.0, force_anomaly))
    else:
        # Generate realistic variation
        # 70% normal (0-0.25), 20% mild (0.25-0.5), 10% anomalous (0.5-1.0)
        r = random.random()
        if r < 0.70:
            anomaly_score = random.uniform(0.02, 0.25)
        elif r < 0.90:
            anomaly_score = random.uniform(0.25, 0.50)
        else:
            anomaly_score = random.uniform(0.50, 0.95)
    
    # Generate plausible metrics based on anomaly level
    baseline_dwell = 82
    baseline_flight = 112
    baseline_wpm = 65
    
    # Deviate metrics based on anomaly score
    deviation = anomaly_score * 2.5  # Max 2.5 std deviations
    
    current_dwell = baseline_dwell + (deviation * 15 * (1 if random.random() > 0.5 else -1))
    current_flight = baseline_flight + (deviation * 22 * (1 if random.random() > 0.5 else -1))
    current_wpm = baseline_wpm + (deviation * 10 * (1 if random.random() > 0.5 else -1))
    
    return {
        "anomaly_score": round(anomaly_score, 4),
        "current_metrics": {
            "dwell_mean_ms": round(max(30, current_dwell), 2),
            "flight_mean_ms": round(max(50, current_flight), 2),
            "wpm": round(max(20, current_wpm), 2),
        },
        "baseline_metrics": {
            "dwell_mean_ms": baseline_dwell,
            "dwell_std_ms": 15,
            "flight_mean_ms": baseline_flight,
            "flight_std_ms": 22,
            "wpm_mean": baseline_wpm,
        },
        "z_scores": {
            "dwell": round(deviation * 0.4, 3),
            "flight": round(deviation * 0.4, 3),
            "wpm": round(deviation * 0.2, 3),
        },
    }


def get_risk_level(anomaly_score: float) -> tuple:
    """Get risk level and recommendation based on anomaly score."""
    if anomaly_score < 0.20:
        return (
            "LOW",
            "Typing pattern matches baseline. Identity confidence high.",
        )
    elif anomaly_score < 0.40:
        return (
            "MEDIUM",
            "Minor typing deviation detected. Continue monitoring.",
        )
    elif anomaly_score < 0.65:
        return (
            "HIGH",
            "Significant typing pattern change. Consider re-authentication.",
        )
    else:
        return (
            "CRITICAL",
            "Possible user switch detected. Initiate verification protocol.",
        )


# ─── API Endpoints ────────────────────────────────────────────

@router.post("/analyze", response_model=KeystrokeAnalyzeResponse)
async def analyze_keystroke(request: KeystrokeAnalyzeRequest):
    """
    Analyze keystroke timing patterns for behavioral anomalies.
    
    - Compares dwell times (key hold duration)
    - Compares flight times (inter-key intervals)
    - Compares typing speed (WPM)
    
    Returns anomaly score (0 = normal, 1 = complete mismatch).
    """
    user_id = request.user_id
    timestamp = datetime.now().isoformat()
    
    # Demo mode or simulation
    if request.demo_mode or user_id not in _enrolled_baselines:
        logger.info(f"Keystroke analyze (demo): user={user_id}")
        
        analysis = simulate_analysis(user_id, request.simulate_anomaly)
    else:
        # Real analysis against enrolled baseline
        logger.info(f"Keystroke analyze (real): user={user_id}")
        
        baseline = _enrolled_baselines[user_id]
        analysis = analyze_keystroke_metrics(request.metrics, baseline)
    
    # Compute match score (inverse of anomaly)
    anomaly_score = analysis["anomaly_score"]
    match_score = (1.0 - anomaly_score) * 100
    
    # Get risk assessment
    risk_level, recommendation = get_risk_level(anomaly_score)
    
    return KeystrokeAnalyzeResponse(
        success=True,
        user_id=user_id,
        anomaly_score=anomaly_score,
        match_score=round(match_score, 2),
        risk_level=risk_level,
        metrics=analysis["current_metrics"],
        deviations=analysis["z_scores"],
        recommendation=recommendation,
        timestamp=timestamp,
    )


@router.post("/enroll", response_model=KeystrokeEnrollResponse)
async def enroll_keystroke(request: KeystrokeEnrollRequest):
    """
    Enroll a typing baseline for a user.
    
    Computes mean and standard deviation for:
    - Dwell times (key hold duration)
    - Flight times (inter-key intervals)
    - WPM (typing speed)
    """
    user_id = request.user_id
    timestamp = datetime.now().isoformat()
    
    # Demo mode
    if request.demo_mode or not request.metrics.dwell_times:
        logger.info(f"Keystroke enroll (demo): user={user_id}")
        
        # Create synthetic baseline
        baseline = {
            "dwell_mean": 82.0,
            "dwell_std": 15.0,
            "flight_mean": 112.0,
            "flight_std": 22.0,
            "wpm_mean": 65.0,
            "wpm_std": 10.0,
            "sample_count": 100,
            "enrolled_at": timestamp,
        }
        _enrolled_baselines[user_id] = baseline
        
        return KeystrokeEnrollResponse(
            success=True,
            user_id=user_id,
            enrolled=True,
            baseline=baseline,
            message="Keystroke baseline enrolled (demo mode)",
            timestamp=timestamp,
        )
    
    # Real enrollment from metrics
    logger.info(f"Keystroke enroll (real): user={user_id}")
    
    metrics = request.metrics
    
    dwell_mean = compute_mean(metrics.dwell_times)
    dwell_std = compute_std(metrics.dwell_times, dwell_mean)
    flight_mean = compute_mean(metrics.flight_times)
    flight_std = compute_std(metrics.flight_times, flight_mean)
    wpm_mean = metrics.wpm if metrics.wpm else 60.0
    
    # Store baseline
    baseline = {
        "dwell_mean": round(dwell_mean, 2),
        "dwell_std": round(max(dwell_std, 5.0), 2),  # Minimum std to avoid division by zero
        "flight_mean": round(flight_mean, 2),
        "flight_std": round(max(flight_std, 5.0), 2),
        "wpm_mean": round(wpm_mean, 2),
        "wpm_std": 10.0,  # Default WPM std
        "sample_count": len(metrics.dwell_times),
        "enrolled_at": timestamp,
    }
    _enrolled_baselines[user_id] = baseline
    
    return KeystrokeEnrollResponse(
        success=True,
        user_id=user_id,
        enrolled=True,
        baseline=baseline,
        message=f"Keystroke baseline enrolled from {len(metrics.dwell_times)} samples",
        timestamp=timestamp,
    )


@router.get("/status")
async def keystroke_service_status():
    """Get keystroke analysis service status."""
    return {
        "service": "keystroke_analysis",
        "status": "online",
        "enrolled_users": len(_enrolled_baselines),
        "analysis_method": "z_score",
        "components_analyzed": ["dwell_time", "flight_time", "wpm"],
    }
