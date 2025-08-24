#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}

# Always place the cb-mpc repository at the project root so running this
# script from any directory doesn't litter the scripts folder.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/../cb-mpc"

# Clone cb-mpc
if [ ! -d "$REPO_DIR" ]; then
  git clone https://github.com/coinbase/cb-mpc.git "$REPO_DIR"
fi
# Test: repository exists
[ -d "$REPO_DIR/.git" ]

cd "$REPO_DIR"
# Ensure submodules fetched (if any)
git submodule update --init --recursive
# Test: presence of Cargo.toml indicates repository ready
[ -f Cargo.toml ]

# Build FFI library
cargo build --release -p cb-mpc-ffi
# Test: library built
[ -f target/release/libcbmpc.a ]

# Install library and header
sudo mkdir -p "$CBMPC_HOME/lib" "$CBMPC_HOME/include"
sudo cp target/release/libcbmpc.a "$CBMPC_HOME/lib/"
# Header path may change; adjust if needed
default_header="ffi/c/include/cbmpc.h"
if [ -f "$default_header" ]; then
  sudo cp "$default_header" "$CBMPC_HOME/include/"
fi
# Tests: verify installation
[ -f "$CBMPC_HOME/lib/libcbmpc.a" ]
[ -f "$CBMPC_HOME/include/cbmpc.h" ]

echo "cb-mpc installed to $CBMPC_HOME"
