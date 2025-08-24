#!/usr/bin/env bash
set -euo pipefail

# Update package index
sudo apt-get update
# Test: ensure apt cache is accessible
apt-cache policy build-essential > /dev/null

echo "Installing build tools and libraries..."
sudo apt-get install -y build-essential cmake pkg-config git curl libcurl4-openssl-dev
# Tests: verify commands installed
command -v g++ >/dev/null
cmake --version >/dev/null
pkg-config --version >/dev/null
git --version >/dev/null
curl --version >/dev/null

echo "Dependency installation complete."
