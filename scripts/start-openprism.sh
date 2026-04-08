#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_KEY="$(printf '%s' "$REPO_ROOT" | cksum | awk '{print $1}')"
ENV_FILE="${OPENPRISM_ENV_FILE:-${REPO_ROOT}/.env.runtime}"
PID_FILE="${OPENPRISM_PID_FILE:-/tmp/openprism-${REPO_KEY}.pid}"
FORCE_BUILD=0

for arg in "$@"; do
  case "$arg" in
    --build|--rebuild)
      FORCE_BUILD=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: bash scripts/start-openprism.sh [--build]" >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

if [[ ! -d node_modules ]]; then
  echo "Missing node_modules. Run 'npm install' first." >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  echo "Copy .env.runtime.example to .env.runtime and edit it first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -f "$PID_FILE" ]]; then
  EXISTING_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${EXISTING_PID:-}" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
    echo "OpenPrism is already running with PID $EXISTING_PID" >&2
    echo "Stop it first with: bash scripts/stop-openprism.sh" >&2
    exit 1
  fi
  rm -f "$PID_FILE"
fi

if [[ "$FORCE_BUILD" -eq 1 || ! -f apps/frontend/dist/index.html ]]; then
  echo "Building frontend..."
  npm run build
fi

echo "Starting OpenPrism from $REPO_ROOT"
echo "Using env file: $ENV_FILE"
echo "Listening on http://127.0.0.1:${PORT:-8787}"

echo "$$" > "$PID_FILE"

exec node apps/backend/src/index.js
