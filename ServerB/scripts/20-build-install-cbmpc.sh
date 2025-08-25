#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

CBMPC_DIR="${CBMPC_DIR:-$HOME/cb-mpc}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"
LLVM_VERSION="${LLVM_VERSION:-20}"
USE_SUDO_INSTALL="${USE_SUDO_INSTALL:-yes}"

export CC="clang-${LLVM_VERSION}"
export CXX="clang++-${LLVM_VERSION}"

if [[ ! -d "${CBMPC_DIR}" ]]; then
  echo "cb-mpc not found at ${CBMPC_DIR}. Run 10-clone-cbmpc.sh first." >&2
  exit 1
fi

echo "[*] Building cb-mpc (this may take a while)..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" build

if [[ "${USE_SUDO_INSTALL}" == "yes" ]]; then
  echo "[*] Installing cb-mpc to /usr/local/opt/cbmpc (sudo)..."
  sudo make -C "${CBMPC_DIR}" install
else
  echo "[*] Skipping 'sudo make install' (USE_SUDO_INSTALL!=yes). Some demos may need headers/libs in /usr/local/opt/cbmpc."
fi

echo "[*] Building demos..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" demos || true

echo "[*] Running unit tests (optional)..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" test || true

echo "[*] Done building cb-mpc."
