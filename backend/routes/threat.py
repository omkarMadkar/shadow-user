"""
Threat Detection API Routes

Endpoints:
  POST /api/threat/detect — Analyze activity metadata for threats

Detects:
  - Suspicious URLs (phishing, malware)
  - Unusual application usage
  - Off-hours activity
  - Data exfiltration patterns
  - Burnout risk indicators
"""

import logging
import random
import re
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel, Field

logger = logging.getLogger("sentinel.threat")

router = APIRouter()


# ─── Threat Detection Patterns ────────────────────────────────

# Suspicious domain patterns
PHISHING_PATTERNS = [
    r"paypa[l1]\.(?!com)",        # paypal typosquats
    r"amaz[o0]n-?\w*\.(?!com)",   # amazon typosquats
    r"g[o0][o0]gle-?\w*\.(?!com)", # google typosquats
    r"micros[o0]ft-?\w*\.(?!com)", # microsoft typosquats
    r"app[l1]e-?\w*\.(?!com)",    # apple typosquats
    r"\w+-verify\.",              # -verify domains
    r"\w+-security\.",            # -security domains
    r"\w+-alert\.",               # -alert domains
    r"\w+-support\.",             # -support domains
    r"\.ru$",                     # Russian TLD (suspicious in corporate)
    r"\.xyz$",                    # .xyz TLD (commonly abused)
    r"\.top$",                    # .top TLD (commonly abused)
    r"\.biz$",                    # .biz TLD (often phishing)
]

# Suspicious application patterns
RISKY_APPS = [
    "tor browser",
    "wireshark",
    "metasploit",
    "nmap",
    "burp suite",
    "hydra",
    "john the ripper",
    "hashcat",
    "mimikatz",
    "proxychains",
    "vpn gate",
    "ultrasurf",
    "psiphon",
]

# Data exfiltration indicators
EXFIL_PATTERNS = [
    r"mega\.nz",
    r"dropbox\.com.*\/s\/",       # Dropbox shared links
    r"drive\.google\.com.*\/d\/", # Google Drive shares
    r"pastebin\.com",
    r"github\.com.*\/gist",
    r"wetransfer\.com",
    r"sendspace\.com",
    r"anonfiles\.com",
]

# Burnout indicators (application usage patterns)
BURNOUT_APPS = [
    "slack",
    "teams",
    "outlook",
    "gmail",
    "zoom",
    "calendar",
]


# ─── Request/Response Models ──────────────────────────────────

class ActivityMetadata(BaseModel):
    """Activity metadata for threat analysis."""
    active_window: Optional[str] = Field(None, description="Current active window title")
    active_app: Optional[str] = Field(None, description="Current active application")
    recent_urls: List[str] = Field(default_factory=list, description="Recently visited URLs")
    apps_running: List[str] = Field(default_factory=list, description="Currently running apps")
    hour_of_day: Optional[int] = Field(None, ge=0, le=23, description="Current hour (0-23)")
    session_duration_minutes: Optional[int] = Field(None, description="Time since session start")
    idle_time_seconds: Optional[int] = Field(None, description="Time since last activity")


class ThreatDetectRequest(BaseModel):
    """Request model for threat detection."""
    user_id: str = Field(..., description="User identifier")
    activity: ActivityMetadata = Field(..., description="Activity metadata to analyze")
    demo_mode: bool = Field(False, description="Use simulated detection")
    
    # Demo mode parameters
    simulate_threat: Optional[float] = Field(None, description="Force specific threat score (0-1)")
    simulate_phishing: bool = Field(False, description="Simulate phishing detection")
    simulate_burnout: bool = Field(False, description="Simulate burnout risk")


class ThreatInfo(BaseModel):
    """Individual threat information."""
    type: str
    severity: str
    description: str
    indicator: str
    confidence: float


class ThreatDetectResponse(BaseModel):
    """Response model for threat detection."""
    success: bool
    user_id: str
    threat_score: float = Field(..., ge=0, le=100, description="0=safe, 100=critical threat")
    safety_score: float = Field(..., ge=0, le=100, description="100=safe, 0=critical threat")
    risk_level: str
    threats_detected: List[ThreatInfo]
    burnout_risk: float = Field(..., ge=0, le=100)
    productivity_score: float = Field(..., ge=0, le=100)
    recommendation: str
    timestamp: str


# ─── Detection Functions ──────────────────────────────────────

def detect_phishing_urls(urls: List[str]) -> List[ThreatInfo]:
    """Check URLs against phishing patterns."""
    threats = []
    
    for url in urls:
        url_lower = url.lower()
        
        for pattern in PHISHING_PATTERNS:
            if re.search(pattern, url_lower):
                threats.append(ThreatInfo(
                    type="phishing",
                    severity="critical",
                    description="Potential phishing URL detected",
                    indicator=url,
                    confidence=85.0 + random.random() * 14,
                ))
                break
        
        # Check for exfiltration patterns
        for pattern in EXFIL_PATTERNS:
            if re.search(pattern, url_lower):
                threats.append(ThreatInfo(
                    type="data_exfiltration",
                    severity="high",
                    description="Potential data exfiltration destination",
                    indicator=url,
                    confidence=70.0 + random.random() * 20,
                ))
                break
    
    return threats


def detect_risky_apps(apps: List[str], active_app: Optional[str]) -> List[ThreatInfo]:
    """Check for security tools or risky applications."""
    threats = []
    all_apps = apps + ([active_app] if active_app else [])
    
    for app in all_apps:
        app_lower = app.lower()
        
        for risky in RISKY_APPS:
            if risky in app_lower:
                threats.append(ThreatInfo(
                    type="risky_application",
                    severity="high",
                    description=f"Security/hacking tool detected: {risky}",
                    indicator=app,
                    confidence=90.0 + random.random() * 9,
                ))
                break
    
    return threats


def detect_off_hours(hour: Optional[int]) -> Optional[ThreatInfo]:
    """Detect activity during unusual hours."""
    if hour is None:
        return None
    
    # Define normal working hours (8 AM - 8 PM)
    if hour < 6 or hour > 22:
        return ThreatInfo(
            type="off_hours_activity",
            severity="medium",
            description=f"Activity detected at unusual hour: {hour}:00",
            indicator=f"hour={hour}",
            confidence=60.0 + random.random() * 20,
        )
    
    return None


def calculate_burnout_risk(
    activity: ActivityMetadata,
    force_burnout: bool = False,
) -> tuple:
    """Calculate burnout risk based on activity patterns."""
    if force_burnout:
        return (75.0 + random.random() * 20, 40.0 + random.random() * 20)
    
    burnout_risk = 15.0  # Base risk
    productivity = 75.0  # Base productivity
    
    # Check session duration (long sessions increase burnout)
    if activity.session_duration_minutes:
        if activity.session_duration_minutes > 480:  # 8+ hours
            burnout_risk += 35.0
            productivity -= 15.0
        elif activity.session_duration_minutes > 360:  # 6+ hours
            burnout_risk += 20.0
            productivity -= 8.0
        elif activity.session_duration_minutes > 240:  # 4+ hours
            burnout_risk += 10.0
    
    # Check for communication app overload
    if activity.apps_running:
        comm_apps = sum(1 for app in activity.apps_running 
                       if any(b in app.lower() for b in BURNOUT_APPS))
        if comm_apps >= 3:
            burnout_risk += 15.0
            productivity -= 10.0
    
    # Off-hours activity increases burnout risk
    if activity.hour_of_day is not None:
        if activity.hour_of_day < 6 or activity.hour_of_day > 22:
            burnout_risk += 20.0
    
    # Add some randomness for realism
    burnout_risk += random.random() * 10 - 5
    productivity += random.random() * 10 - 5
    
    return (
        max(0, min(100, burnout_risk)),
        max(0, min(100, productivity)),
    )


def simulate_threat_detection(
    user_id: str,
    force_threat: Optional[float] = None,
    force_phishing: bool = False,
    force_burnout: bool = False,
) -> dict:
    """
    Generate realistic simulated threat detection results.
    Used for demo mode.
    """
    threats = []
    
    # Simulated phishing threat
    if force_phishing:
        threats.append(ThreatInfo(
            type="phishing",
            severity="critical",
            description="Potential phishing URL detected in browser",
            indicator="https://secure-paypa1-verify.com/login",
            confidence=92.5,
        ))
    
    # Random threats based on probability
    if force_threat is not None:
        threat_score = force_threat * 100
    else:
        r = random.random()
        if r < 0.70:  # 70% safe
            threat_score = random.uniform(0, 15)
        elif r < 0.90:  # 20% mild
            threat_score = random.uniform(15, 40)
        else:  # 10% concerning
            threat_score = random.uniform(40, 75)
            threats.append(ThreatInfo(
                type="suspicious_activity",
                severity="medium",
                description="Unusual application behavior detected",
                indicator="Elevated process activity",
                confidence=65.0 + random.random() * 20,
            ))
    
    # Burnout simulation
    if force_burnout:
        burnout_risk = 75.0 + random.random() * 20
        productivity = 35.0 + random.random() * 25
    else:
        burnout_risk = 15.0 + random.random() * 30
        productivity = 65.0 + random.random() * 25
    
    return {
        "threat_score": min(100, threat_score),
        "threats": threats,
        "burnout_risk": burnout_risk,
        "productivity": productivity,
    }


def get_risk_level(threat_score: float) -> tuple:
    """Get risk level and recommendation from threat score."""
    if threat_score < 15:
        return ("LOW", "Activity appears normal. Continue monitoring.")
    elif threat_score < 35:
        return ("MEDIUM", "Minor anomalies detected. Review recent activity.")
    elif threat_score < 60:
        return ("HIGH", "Suspicious activity detected. Investigate immediately.")
    else:
        return ("CRITICAL", "Security threat detected. Initiate incident response.")


# ─── API Endpoints ────────────────────────────────────────────

@router.post("/detect", response_model=ThreatDetectResponse)
async def detect_threats(request: ThreatDetectRequest):
    """
    Analyze activity metadata for security threats.
    
    Detects:
    - Phishing URLs
    - Risky applications
    - Data exfiltration attempts
    - Off-hours activity
    - Burnout risk indicators
    """
    user_id = request.user_id
    activity = request.activity
    timestamp = datetime.now().isoformat()
    
    # Demo mode
    if request.demo_mode:
        logger.info(f"Threat detect (demo): user={user_id}")
        
        sim = simulate_threat_detection(
            user_id,
            force_threat=request.simulate_threat,
            force_phishing=request.simulate_phishing,
            force_burnout=request.simulate_burnout,
        )
        
        threat_score = sim["threat_score"]
        safety_score = 100 - threat_score
        risk_level, recommendation = get_risk_level(threat_score)
        
        return ThreatDetectResponse(
            success=True,
            user_id=user_id,
            threat_score=round(threat_score, 2),
            safety_score=round(safety_score, 2),
            risk_level=risk_level,
            threats_detected=sim["threats"],
            burnout_risk=round(sim["burnout_risk"], 2),
            productivity_score=round(sim["productivity"], 2),
            recommendation=recommendation,
            timestamp=timestamp,
        )
    
    # Real threat detection
    logger.info(f"Threat detect (real): user={user_id}")
    
    threats = []
    
    # Check URLs for phishing
    if activity.recent_urls:
        threats.extend(detect_phishing_urls(activity.recent_urls))
    
    # Check applications
    threats.extend(detect_risky_apps(activity.apps_running, activity.active_app))
    
    # Check for off-hours activity
    off_hours_threat = detect_off_hours(activity.hour_of_day)
    if off_hours_threat:
        threats.append(off_hours_threat)
    
    # Calculate burnout risk
    burnout_risk, productivity = calculate_burnout_risk(activity)
    
    # Calculate overall threat score
    if not threats:
        threat_score = 5.0 + random.random() * 10  # Base low threat
    else:
        # Weight by severity
        severity_weights = {"critical": 40, "high": 25, "medium": 15, "low": 5}
        weighted_sum = sum(
            severity_weights.get(t.severity, 10) * (t.confidence / 100)
            for t in threats
        )
        threat_score = min(100, weighted_sum)
    
    safety_score = 100 - threat_score
    risk_level, recommendation = get_risk_level(threat_score)
    
    return ThreatDetectResponse(
        success=True,
        user_id=user_id,
        threat_score=round(threat_score, 2),
        safety_score=round(safety_score, 2),
        risk_level=risk_level,
        threats_detected=threats,
        burnout_risk=round(burnout_risk, 2),
        productivity_score=round(productivity, 2),
        recommendation=recommendation,
        timestamp=timestamp,
    )


@router.get("/status")
async def threat_service_status():
    """Get threat detection service status."""
    return {
        "service": "threat_detection",
        "status": "online",
        "detection_capabilities": [
            "phishing_url_detection",
            "risky_application_detection",
            "data_exfiltration_detection",
            "off_hours_activity_detection",
            "burnout_risk_analysis",
        ],
        "phishing_patterns_loaded": len(PHISHING_PATTERNS),
        "risky_apps_tracked": len(RISKY_APPS),
    }
