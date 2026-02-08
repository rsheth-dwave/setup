#!/bin/bash

set -euo pipefail

PORT="${JUPYTER_PORT:-8888}"
TOKEN="${JUPYTER_TOKEN:-dev}"

# Start Jupyter in the background
jupyter lab \
  --ip=0.0.0.0 \
  --port="${PORT}" \
  --no-browser \
  --ServerApp.token="${TOKEN}" \
  --ServerApp.allow_remote_access=1 \
  > /tmp/jupyter.log 2>&1 &

echo "Jupyter running on :${PORT} (token=${TOKEN}). Log: /tmp/jupyter.log" >&2
echo "Connect in VS Code web at http://127.0.0.1:8888/?token=${TOKEN}"

# Run whatever command was passed (keeps container alive)
exec "$@"

