#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

OPENSSL_VER="${OPENSSL_VER:-3.2.0}"
BUILD_STATIC_OPENSSL="${BUILD_STATIC_OPENSSL:-yes}"
OPENSSL_PREFIX="${OPENSSL_PREFIX:-/usr/local/opt/openssl@${OPENSSL_VER}}"

if [[ "${BUILD_STATIC_OPENSSL}" != "yes" ]]; then
  echo "[*] BUILD_STATIC_OPENSSL is not 'yes'; skipping OpenSSL build."
  exit 0
fi

# If already present, skip
if [[ -f "${OPENSSL_PREFIX}/lib64/libcrypto.a" && -f "${OPENSSL_PREFIX}/lib64/libssl.a" ]]; then
  echo "[*] Found static OpenSSL at ${OPENSSL_PREFIX}; skipping build."
  exit 0
fi

bash "$(dirname "$0")/openssl/build-static-openssl-linux.sh"
