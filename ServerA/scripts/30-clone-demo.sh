#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

DEMO_DIR="${DEMO_DIR:-$HOME/cb-mpc-demo}"

if [[ -d "${DEMO_DIR}/.git" ]]; then
  echo "[*] Demo repo already present at ${DEMO_DIR}; pulling latest..."
  git -C "${DEMO_DIR}" fetch --all --tags
  git -C "${DEMO_DIR}" checkout main || true
  git -C "${DEMO_DIR}" pull --rebase || true
else
  echo "[*] Cloning demo repo into ${DEMO_DIR}..."
  git clone https://github.com/reflectionwaves/cb-mpc-demo "${DEMO_DIR}"
fi

echo "[*] Done."
