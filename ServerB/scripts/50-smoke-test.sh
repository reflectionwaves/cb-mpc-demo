#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

CBMPC_DIR="${CBMPC_DIR:-$HOME/cb-mpc}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"

if [[ -d "${CBMPC_DIR}" ]]; then
  echo "[*] Running cb-mpc unit tests..."
  make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" test || true
else
  echo "[*] cb-mpc not found at ${CBMPC_DIR}, skipping tests."
fi
