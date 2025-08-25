#!/usr/bin/env bash
# Build a static OpenSSL and install to /usr/local/opt/openssl@${OPENSSL_VER}/lib64/
set -euo pipefail
source "$(dirname "$0")/../../env" 2>/dev/null || source "$(dirname "$0")/../../env.sample"

OPENSSL_VER="${OPENSSL_VER:-3.2.0}"
OPENSSL_PREFIX="${OPENSSL_PREFIX:-/usr/local/opt/openssl@${OPENSSL_VER}}"
TARBALL="openssl-${OPENSSL_VER}.tar.gz"
SRC_URL_PRIMARY="https://www.openssl.org/source/${TARBALL}"
SRC_URL_FALLBACK="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VER}/${TARBALL}"

echo "[*] Building static OpenSSL ${OPENSSL_VER} into ${OPENSSL_PREFIX} ..."
sudo mkdir -p /usr/local/opt
sudo chown "$(id -u)":"$(id -g)" /usr/local/opt

# Required build tools should already be present (perl, build-essential, nasm)
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

echo "[*] Downloading ${TARBALL} ..."
if ! curl -fsSLO "${SRC_URL_PRIMARY}"; then
  echo "[!] Primary source failed; trying GitHub mirror ..."
  curl -fsSLO "${SRC_URL_FALLBACK}"
fi

tar xzf "${TARBALL}"
cd "openssl-${OPENSSL_VER}"

arch="$(uname -m)"
case "$arch" in
  x86_64) target="linux-x86_64" ;;
  aarch64|arm64) target="linux-aarch64" ;;
  *) echo "Unsupported arch: $arch" >&2; exit 1 ;;
esac

echo "[*] Configuring for ${target} (static libs, lib64)..."
./Configure "${target}" no-shared --prefix="${OPENSSL_PREFIX}" --openssldir="${OPENSSL_PREFIX}/ssl" --libdir=lib64

make -j"$(nproc)"
sudo make install_sw

echo "[*] Installed files:"
ls -l "${OPENSSL_PREFIX}/lib64/libcrypto.a" "${OPENSSL_PREFIX}/lib64/libssl.a"

echo "[*] Static OpenSSL ${OPENSSL_VER} ready."
