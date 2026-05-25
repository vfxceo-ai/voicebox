# ============================================================
# Voicebox — Web UI + FastAPI backend for GPU deployments
# 3-stage build: Frontend → Python deps → Runtime
# ============================================================

# === Stage 1: Build frontend ===
FROM oven/bun:1 AS frontend

WORKDIR /build

COPY package.json bun.lock CHANGELOG.md ./
COPY app/ ./app/
COPY web/ ./web/

RUN sed -i '/"tauri"/d; /"landing"/d' package.json && \
    sed -i -z 's/,\n  ]/\n  ]/' package.json
RUN bun install --no-save
# Upstream web build currently succeeds even when full workspace type-checking does not.
RUN cd web && bunx --bun vite build

# === Stage 2: Build Python dependencies ===
FROM python:3.11-slim AS backend-builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip

COPY backend/requirements.txt .

# Preinstall CUDA-enabled PyTorch wheels so NVIDIA-backed workloads use the GPU path.
RUN pip install --no-cache-dir --prefix=/install \
    --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
RUN pip install --no-cache-dir --prefix=/install --no-deps chatterbox-tts
RUN pip install --no-cache-dir --prefix=/install --no-deps hume-tada
RUN pip install --no-cache-dir --prefix=/install \
    git+https://github.com/QwenLM/Qwen3-TTS.git

# === Stage 3: Runtime ===
FROM python:3.11-slim

RUN groupadd -r voicebox && \
    useradd -r -g voicebox -m -s /bin/bash voicebox

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=backend-builder /install /usr/local

COPY --chown=voicebox:voicebox backend/ /app/backend/
COPY --from=frontend --chown=voicebox:voicebox /build/web/dist /app/frontend/
COPY --chown=voicebox:voicebox entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh && \
    mkdir -p /data/voicebox /models && \
    chown -R voicebox:voicebox /app /data /models

USER voicebox

ENV HOST=0.0.0.0
ENV PORT=17493
ENV VOICEBOX_DATA_DIR=/data/voicebox
ENV VOICEBOX_MODELS_DIR=/models
ENV HF_HOME=/models
ENV HF_HUB_CACHE=/models
ENV NUMBA_CACHE_DIR=/tmp/numba_cache

EXPOSE 17493

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
    CMD curl -f "http://127.0.0.1:${PORT}/health" || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
