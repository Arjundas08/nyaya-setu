FROM python:3.10-slim

# ── System dependencies ──
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# ── Create non-root user ──
RUN useradd -m -u 1000 user
ENV PATH="/home/user/.local/bin:$PATH"

WORKDIR /app

# ── Install Python dependencies (cached layer) ──
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --timeout 120 -r requirements.txt

# ── Pre-download PaddleOCR models during build ──
RUN python -c "from paddleocr import PaddleOCR; PaddleOCR(use_angle_cls=True, lang='en')" || true

# ── Copy project files ──
COPY --chown=user . /app

# ── Build ChromaDB knowledge base ──
ENV BUILD_MODE=docker
RUN python scripts/build_knowledge_base.py || echo "WARNING: Knowledge base build had issues"

# ── Switch to non-root user ──
USER user

# Hugging Face exposes this one port
EXPOSE 7860

# Simple: FastAPI on 8000 (internal) + Streamlit on 7860 (exposed)
CMD ["bash", "-c", "uvicorn backend.main:app --host 0.0.0.0 --port 8000 & streamlit run frontend/app.py --server.port 7860 --server.address 0.0.0.0 --server.headless true --server.enableCORS false --server.enableXsrfProtection false"]