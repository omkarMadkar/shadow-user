@echo off
REM Shadow Sentinel Backend — Startup Script (Windows)

echo ==============================================
echo   SHADOW SENTINEL BACKEND
echo   Zero Trust Continuous Authentication API
echo ==============================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate

REM Install dependencies
echo Installing dependencies...
pip install -q -r requirements.txt

echo.
echo Starting server on http://localhost:8000
echo Press Ctrl+C to stop
echo.

REM Run the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
