#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

CBMPC_DIR="${CBMPC_DIR:-$HOME/cb-mpc}"
CBMPC_BRANCH="${CBMPC_BRANCH:-master}"

if [[ -d "${CBMPC_DIR}/.git" ]]; then
  echo "[*] cb-mpc already present at ${CBMPC_DIR}; pulling latest..."
  git -C "${CBMPC_DIR}" fetch --all --tags
  git -C "${CBMPC_DIR}" checkout "${CBMPC_BRANCH}"
  git -C "${CBMPC_DIR}" pull --rebase
else
  echo "[*] Cloning cb-mpc into ${CBMPC_DIR}..."
  git clone --depth=1 --branch "${CBMPC_BRANCH}" https://github.com/coinbase/cb-mpc "${CBMPC_DIR}"
fi

echo "[*] Initializing submodules (recursive)..."
git -C "${CBMPC_DIR}" submodule update --init --recursive

echo "[*] Done."
