#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/services/bootstrap-signer"

export ZSIGN_PATH="${ZSIGN_PATH:-$ROOT/Zsign/bin/zsign}"
export BOOTSTRAP_PUBLIC_URL="${BOOTSTRAP_PUBLIC_URL:-http://127.0.0.1:8787}"
export BOOTSTRAP_CORS_ORIGINS="${BOOTSTRAP_CORS_ORIGINS:-http://127.0.0.1:5500,http://127.0.0.1:8787,http://localhost:5500}"

if [[ ! -x "$ZSIGN_PATH" ]]; then
  echo "Building zsign…"
  make -C "$ROOT/Zsign/build/macos" 2>/dev/null || make -C "$ROOT/Zsign/build/linux"
fi

pip install -q -r requirements.txt
exec uvicorn main:app --host 127.0.0.1 --port 8787 --reload
