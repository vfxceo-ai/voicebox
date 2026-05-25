#!/bin/sh
set -eu

VOICEBOX_DATA_DIR="${VOICEBOX_DATA_DIR:-/data/voicebox}"
VOICEBOX_MODELS_DIR="${VOICEBOX_MODELS_DIR:-/models}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-17493}"

export VOICEBOX_DATA_DIR
export VOICEBOX_MODELS_DIR
export HF_HOME="${HF_HOME:-$VOICEBOX_MODELS_DIR}"
export HF_HUB_CACHE="${HF_HUB_CACHE:-$VOICEBOX_MODELS_DIR}"
export NUMBA_CACHE_DIR="${NUMBA_CACHE_DIR:-/tmp/numba_cache}"

mkdir -p \
  "$VOICEBOX_DATA_DIR" \
  "$VOICEBOX_DATA_DIR/profiles" \
  "$VOICEBOX_DATA_DIR/generations" \
  "$VOICEBOX_DATA_DIR/cache" \
  "$VOICEBOX_DATA_DIR/backends" \
  "$VOICEBOX_MODELS_DIR" \
  "$NUMBA_CACHE_DIR"

exec python -m backend.main \
  --host "$HOST" \
  --port "$PORT" \
  --data-dir "$VOICEBOX_DATA_DIR"
