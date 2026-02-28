# Shadow Sentinel Backend — Python REST API

AI-powered continuous authentication and threat detection microservices.

## Quick Start

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Run the Server

```bash
# Development mode (with auto-reload)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Or simply:
python main.py
```

### 4. Verify It's Running

Open: http://localhost:8000/health

You should see:
```json
{
  "status": "healthy",
  "service": "shadow-sentinel-api",
  "version": "1.0.0"
}
```

---

## API Endpoints

### Health Check
```
GET /health
```

### Face Verification
```
POST /api/face/verify
{
  "user_id": "user123",
  "image_base64": "...",  // Optional
  "demo_mode": true       // Use simulation
}

POST /api/face/enroll
{
  "user_id": "user123",
  "image_base64": "...",
  "demo_mode": true
}
```

### Keystroke Analysis
```
POST /api/keystroke/analyze
{
  "user_id": "user123",
  "metrics": {
    "dwell_times": [80, 85, 75, 90, ...],
    "flight_times": [100, 110, 95, 120, ...],
    "wpm": 65,
    "key_count": 150
  },
  "demo_mode": true
}

POST /api/keystroke/enroll
{
  "user_id": "user123",
  "metrics": { ... },
  "demo_mode": true
}
```

### Threat Detection
```
POST /api/threat/detect
{
  "user_id": "user123",
  "activity": {
    "active_window": "Chrome - Gmail",
    "active_app": "Google Chrome",
    "recent_urls": ["https://example.com"],
    "apps_running": ["Chrome", "Slack", "VS Code"],
    "hour_of_day": 14,
    "session_duration_minutes": 120
  },
  "demo_mode": true
}
```

### Trust Score Calculation
```
POST /api/trust/score
{
  "face_confidence": 95.5,
  "keystroke_match": 87.2,
  "activity_safety": 92.0
}
```

---

## Demo Mode

All endpoints support `demo_mode: true` for hackathon demos.

### Simulate Specific Scenarios

**Identity Mismatch:**
```json
POST /api/face/verify
{
  "user_id": "user123",
  "demo_mode": true,
  "simulate_match": false
}
```

**Spoofing Attempt:**
```json
POST /api/face/verify
{
  "user_id": "user123",
  "demo_mode": true,
  "simulate_spoofing": true
}
```

**Keystroke Anomaly:**
```json
POST /api/keystroke/analyze
{
  "user_id": "user123",
  "metrics": {},
  "demo_mode": true,
  "simulate_anomaly": 0.8
}
```

**Phishing Detection:**
```json
POST /api/threat/detect
{
  "user_id": "user123",
  "activity": {},
  "demo_mode": true,
  "simulate_phishing": true
}
```

**Burnout Risk:**
```json
POST /api/threat/detect
{
  "user_id": "user123",
  "activity": {},
  "demo_mode": true,
  "simulate_burnout": true
}
```

---

## Trust Score Formula

```
Trust Score = (0.40 × Face Match %) + 
              (0.40 × Keystroke Match %) + 
              (0.20 × Activity Safety %)
```

### Risk Levels

| Score | Level | Action |
|-------|-------|--------|
| 80-100 | LOW | Normal operation |
| 60-79 | MEDIUM | Continue monitoring |
| 40-59 | HIGH | Recommend re-authentication |
| 0-39 | CRITICAL | Initiate lockdown protocol |

---

## OpenCV Face Detection

The backend uses OpenCV for real face detection when available:

```bash
pip install opencv-python-headless
```

If OpenCV is unavailable, the API automatically falls back to simulation mode.

---

## Architecture

```
backend/
├── main.py              # FastAPI application entry
├── requirements.txt     # Python dependencies
├── routes/
│   ├── __init__.py
│   ├── face.py         # Face verification endpoints
│   ├── keystroke.py    # Keystroke analysis endpoints
│   └── threat.py       # Threat detection endpoints
└── README.md           # This file
```

---

## CORS

CORS is enabled for all origins (`*`) for hackathon demo purposes.

In production, restrict to specific Flutter app origins.

---

## License

Shadow Sentinel — Zero Trust Continuous Authentication Platform
Hackathon Project 2026
