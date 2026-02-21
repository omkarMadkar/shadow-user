"""
Content Threat Analysis API Route

Endpoints:
  POST /api/content/analyze — Analyze typed text for threatening content
  
Detects:
  - Profanity / vulgar language
  - Hostile / aggressive language  
  - Threats of violence
  - Harassment / discriminatory language
  - Backspace cover-up attempts (typed then deleted abusive content)
  - Sent threatening messages (Enter pressed with flagged content)
"""

import logging
import re
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel, Field

logger = logging.getLogger("sentinel.content")

router = APIRouter()


# ─── Threat Dictionaries ──────────────────────────────────────

PROFANITY = [
    "fuck", "shit", "damn", "bitch", "ass", "bastard", "crap", "dick",
    "piss", "slut", "whore", "moron", "idiot", "dumbass", "bullshit",
    "asshole", "motherfucker", "wtf", "stfu",
]

HOSTILITY = [
    "hate you", "shut up", "get lost", "go to hell", "screw you",
    "i hate", "piss off", "back off", "drop dead", "leave me alone",
    "you suck", "piece of garbage", "worthless", "loser", "pathetic",
    "disgusting", "useless", "incompetent", "garbage", "terrible person",
]

THREATS = [
    "kill you", "gonna kill", "i will kill", "murder", "destroy you",
    "beat you up", "hurt you", "punch you", "break your",
    "watch your back", "you are dead", "you're dead", "end you",
    "finish you", "regret this", "pay for this", "revenge",
    "bomb", "shoot", "weapon", "gun", "knife", "stab",
]

HARASSMENT = [
    "retard", "faggot", "nigger", "chink", "spic", "kike", "tranny",
    "cripple", "freak", "go back to your country", "you people",
    "your kind", "don't belong",
]

NEGATIVE = [
    "i can't take this", "so frustrated", "i give up", "this is hopeless",
    "stressed out", "overwhelmed", "burned out", "exhausted", "fed up",
    "sick of this", "done with this", "can't stand", "terrible",
    "horrible", "awful", "worst", "nightmare", "angry", "furious",
    "annoyed", "irritated", "pissed",
]


# ─── Request/Response Models ──────────────────────────────────

class ContentAnalyzeRequest(BaseModel):
    """Request model for content threat analysis."""
    user_id: str = Field(..., description="User identifier")
    typed_text: str = Field("", description="Currently typed text")
    deleted_text: str = Field("", description="Text that was backspaced/deleted")
    foreground_app: str = Field("", description="Active application window title")
    was_sent: bool = Field(False, description="Whether Enter was pressed (message sent)")
    

class ContentFlag(BaseModel):
    """A detected content flag."""
    category: str  # profanity, hostility, threat, harassment, negative
    severity: int  # 0-100
    matched_words: List[str]
    

class ContentAnalyzeResponse(BaseModel):
    """Response model for content threat analysis."""
    success: bool
    user_id: str
    is_flagged: bool
    threat_score: int = Field(..., ge=0, le=100)
    flags: List[ContentFlag]
    alert_type: str  # none, live_typing, backspace_coverup, sent_threatening
    tone: str  # neutral, stressed, aggressive, hostile
    recommendation: str
    foreground_app: str
    timestamp: str


# ─── Analysis Functions ───────────────────────────────────────

def scan_text(text: str) -> List[ContentFlag]:
    """Scan text against all threat dictionaries."""
    if not text or not text.strip():
        return []
    
    lower = text.lower()
    flags = []
    
    def check_category(words: List[str], category: str, severity: int):
        matched = [w for w in words if w in lower]
        if matched:
            flags.append(ContentFlag(
                category=category,
                severity=severity,
                matched_words=matched,
            ))
    
    check_category(THREATS, "threat", 90)
    check_category(HARASSMENT, "harassment", 85)
    check_category(HOSTILITY, "hostility", 70)
    check_category(PROFANITY, "profanity", 60)
    check_category(NEGATIVE, "negative", 30)
    
    return flags


def get_tone(flags: List[ContentFlag]) -> str:
    """Determine overall tone from flags."""
    if not flags:
        return "neutral"
    max_severity = max(f.severity for f in flags)
    if max_severity >= 85:
        return "hostile"
    if max_severity >= 60:
        return "aggressive"
    if max_severity >= 30:
        return "stressed"
    return "neutral"


# ─── API Endpoint ─────────────────────────────────────────────

@router.post("/analyze", response_model=ContentAnalyzeResponse)
async def analyze_content(request: ContentAnalyzeRequest):
    """
    Analyze typed text content for threats, abuse, and cover-up attempts.
    
    Checks both the live typed text AND any deleted text (backspace cover-up).
    If Enter was pressed (was_sent=True), flags it as sent threatening content.
    """
    user_id = request.user_id
    timestamp = datetime.now().isoformat()
    
    # Scan both typed and deleted text
    typed_flags = scan_text(request.typed_text)
    deleted_flags = scan_text(request.deleted_text)
    
    all_flags = typed_flags + deleted_flags
    is_flagged = len(all_flags) > 0
    threat_score = max((f.severity for f in all_flags), default=0)
    
    # Determine alert type
    if deleted_flags and any(f.severity >= 40 for f in deleted_flags):
        alert_type = "backspace_coverup"
        recommendation = (
            "ALERT: User typed threatening content then deleted it. "
            "This may indicate intent to send abusive messages. "
            f"Deleted content flagged in [{request.foreground_app}]."
        )
        logger.warning(
            f"BACKSPACE COVER-UP: user={user_id} app={request.foreground_app} "
            f"deleted_flags={[f.category for f in deleted_flags]}"
        )
    elif request.was_sent and typed_flags and any(f.severity >= 60 for f in typed_flags):
        alert_type = "sent_threatening"
        recommendation = (
            "CRITICAL: Threatening content was sent/submitted. "
            f"Application: [{request.foreground_app}]. "
            "Recommend immediate review and possible intervention."
        )
        logger.warning(
            f"SENT THREATENING: user={user_id} app={request.foreground_app} "
            f"flags={[f.category for f in typed_flags]}"
        )
    elif typed_flags and any(f.severity >= 50 for f in typed_flags):
        alert_type = "live_typing"
        recommendation = (
            "Potentially threatening content being typed. "
            "Continue monitoring for escalation."
        )
        logger.info(
            f"LIVE THREAT: user={user_id} app={request.foreground_app} "
            f"flags={[f.category for f in typed_flags]}"
        )
    else:
        alert_type = "none"
        recommendation = "Content appears safe. No action needed."
    
    tone = get_tone(all_flags)
    
    return ContentAnalyzeResponse(
        success=True,
        user_id=user_id,
        is_flagged=is_flagged,
        threat_score=threat_score,
        flags=all_flags,
        alert_type=alert_type,
        tone=tone,
        recommendation=recommendation,
        foreground_app=request.foreground_app,
        timestamp=timestamp,
    )
