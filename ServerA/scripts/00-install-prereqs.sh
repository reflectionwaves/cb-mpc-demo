#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
source /etc/os-release
CODENAME="${UBUNTU_CODENAME:-noble}"
LLVM_VERSION="${LLVM_VERSION:-20}"

echo "[*] Updating apt and installing base build tools..."
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  apt-transport-https ca-certificates gnupg software-properties-common lsb-release \
  build-essential cmake make ninja-build pkg-config git git-lfs curl wget unzip tar \
  python3 python3-pip python3-venv \
  libssl-dev libgmp-dev \
  golang-go perl nasm

echo "[*] Adding LLVM apt repo for clang-${LLVM_VERSION}..."
if [[ ! -f /etc/apt/trusted.gpg.d/apt.llvm.org.asc ]]; then
  curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null
fi

echo "deb http://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${LLVM_VERSION} main" | \
  sudo tee /etc/apt/sources.list.d/llvm-${LLVM_VERSION}.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  "clang-${LLVM_VERSION}" "lld-${LLVM_VERSION}" "llvm-${LLVM_VERSION}" "clang-format-${LLVM_VERSION}"

echo "[*] Verifying clang version..."
"clang-${LLVM_VERSION}" --version || { echo "clang-${LLVM_VERSION} not found"; exit 1; }
"clang++-${LLVM_VERSION}" --version || { echo "clang++-${LLVM_VERSION} not found"; exit 1; }

git lfs install || true
echo "[*] Done: prerequisites installed."
