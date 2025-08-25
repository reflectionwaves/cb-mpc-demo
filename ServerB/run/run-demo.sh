#!/usr/bin/env bash
# Heuristic runner for your cb-mpc-demo. Adjust DEMO_DIR or the patterns below if needed.
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

DEMO_DIR="${DEMO_DIR:-$HOME/cb-mpc-demo}"
ROLE="${ROLE:-A}"
SELF_HOST="${SELF_HOST:-0.0.0.0}"
SELF_PORT="${SELF_PORT:-7001}"
PEER_HOST="${PEER_HOST:-127.0.0.1}"
PEER_PORT="${PEER_PORT:-7002}"

# Common candidates to run
candidates=(
  "${DEMO_DIR}/build/demo"
  "${DEMO_DIR}/build/app"
  "${DEMO_DIR}/build/server_${ROLE,,}"
  "${DEMO_DIR}/Server${ROLE}/build/server${ROLE}"
  "${DEMO_DIR}/Server${ROLE}/server${ROLE}"
  "${DEMO_DIR}/run.sh"
)

for c in "${candidates[@]}"; do
  if [[ -x "$c" ]]; then
    echo "[*] Running: $c --role ${ROLE} --self ${SELF_HOST}:${SELF_PORT} --peer ${PEER_HOST}:${PEER_PORT}"
    exec "$c" --role "${ROLE}" --self "${SELF_HOST}:${SELF_PORT}" --peer "${PEER_HOST}:${PEER_PORT}"
  elif [[ -f "$c" ]]; then
    # If it's a script but not executable, run with bash
    echo "[*] Running (bash): $c ${ROLE} ${SELF_HOST}:${SELF_PORT} ${PEER_HOST}:${PEER_PORT}"
    exec bash "$c" "${ROLE}" "${SELF_HOST}:${SELF_PORT}" "${PEER_HOST}:${PEER_PORT}"
  fi
done

cat <<EOF
[!] Could not auto-detect a runnable target in ${DEMO_DIR}.
Tried:
$(printf '  - %s\n' "${candidates[@]}")

Next steps:
  1) Build your demo (try: ./scripts/40-build-demo.sh)
  2) Re-run this script, or run your demo manually.

EOF
exit 1
