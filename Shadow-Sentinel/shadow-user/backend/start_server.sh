#!/bin/bash
# Shadow Sentinel Backend — Startup Script

echo "=============================================="
echo "  SHADOW SENTINEL BACKEND"
echo "  Zero Trust Continuous Authentication API"
echo "=============================================="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q -r requirements.txt

echo ""
echo "Starting server on http://localhost:8000"
echo "Press Ctrl+C to stop"
echo ""

# Run the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
