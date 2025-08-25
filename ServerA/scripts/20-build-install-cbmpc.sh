#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

CBMPC_DIR="${CBMPC_DIR:-$HOME/cb-mpc}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"
LLVM_VERSION="${LLVM_VERSION:-20}"
USE_SUDO_INSTALL="${USE_SUDO_INSTALL:-yes}"
OPENSSL_VER="${OPENSSL_VER:-3.2.0}"
OPENSSL_PREFIX="${OPENSSL_PREFIX:-/usr/local/opt/openssl@${OPENSSL_VER}}"

export CC="clang-${LLVM_VERSION}"
export CXX="clang++-${LLVM_VERSION}"

# Help CMake find our static OpenSSL and prefer it
export OPENSSL_ROOT_DIR="${OPENSSL_PREFIX}"
export OPENSSL_CRYPTO_LIBRARY="${OPENSSL_PREFIX}/lib64/libcrypto.a"
export OPENSSL_SSL_LIBRARY="${OPENSSL_PREFIX}/lib64/libssl.a"
export CMAKE_PREFIX_PATH="${OPENSSL_PREFIX}:${CMAKE_PREFIX_PATH:-}"
export LDFLAGS="-L${OPENSSL_PREFIX}/lib64 ${LDFLAGS:-}"
export CPPFLAGS="-I${OPENSSL_PREFIX}/include ${CPPFLAGS:-}"

if [[ ! -d "${CBMPC_DIR}" ]]; then
  echo "cb-mpc not found at ${CBMPC_DIR}. Run 10-clone-cbmpc.sh first." >&2
  exit 1
fi

echo "[*] Cleaning previous build to ensure OpenSSL paths are picked up..."
rm -rf "${CBMPC_DIR}/build"

echo "[*] Building cb-mpc (make build)..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" build

if [[ "${USE_SUDO_INSTALL}" == "yes" ]]; then
  echo "[*] Installing cb-mpc to /usr/local/opt/cbmpc (sudo make install)..."
  sudo make -C "${CBMPC_DIR}" install
else
  echo "[*] Skipping 'sudo make install' (USE_SUDO_INSTALL!=yes)."
fi

echo "[*] Building demos (optional)..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" demos || true

echo "[*] Running unit tests (optional)..."
make -C "${CBMPC_DIR}" -j"${PARALLEL_JOBS}" test || true

echo "[*] Done building cb-mpc."
