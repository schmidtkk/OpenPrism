#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_KEY="$(printf '%s' "$REPO_ROOT" | cksum | awk '{print $1}')"
ENV_FILE="${OPENPRISM_ENV_FILE:-${REPO_ROOT}/.env.runtime}"
PID_FILE="${OPENPRISM_PID_FILE:-/tmp/openprism-${REPO_KEY}.pid}"
PORT=8787

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

find_port_pid() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1
    return
  fi
  if command -v fuser >/dev/null 2>&1; then
    fuser "$PORT"/tcp 2>/dev/null | awk '{print $1}'
    return
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$PORT" 2>/dev/null | awk -F 'pid=' 'NF>1 {split($2,a,","); print a[1]; exit}'
    return
  fi
}

PID=""
if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
fi

if [[ -z "${PID:-}" ]] || ! kill -0 "$PID" 2>/dev/null; then
  PID="$(find_port_pid || true)"
fi

if [[ -z "${PID:-}" ]]; then
  rm -f "$PID_FILE"
  echo "OpenPrism is not running."
  exit 0
fi

echo "Stopping OpenPrism PID $PID"
kill "$PID" 2>/dev/null || true

for _ in $(seq 1 30); do
  if ! kill -0 "$PID" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "OpenPrism stopped."
    exit 0
  fi
  sleep 1
done

echo "Process did not exit after 30s; sending SIGKILL."
kill -9 "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo "OpenPrism stopped."
