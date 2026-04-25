#!/bin/bash

echo "Starting Nyaya-Setu Services (Non-Root Mode)..."

# 1. Start FastAPI backend in background
echo "Launching FastAPI (Port 8000)..."
uvicorn backend.main:app --host 127.0.0.1 --port 8000 &

# 2. Start Streamlit in background
echo "Launching Streamlit (Port 8501)..."
streamlit run frontend/app.py \
  --server.port 8501 \
  --server.address 127.0.0.1 \
  --server.headless true \
  --server.enableCORS false \
  --browser.usageStats false &

# 3. Start Nginx in foreground (Port 7860)
echo "Launching Nginx Proxy (Port 7860)..."
nginx -c /etc/nginx/nginx.conf -g "daemon off;"