#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}

# Place the cb-mpc sources under CBMPC_HOME to avoid cluttering the project tree.
REPO_DIR="$CBMPC_HOME/cb-mpc"

# Clone cb-mpc
if [ ! -d "$REPO_DIR" ]; then
  sudo mkdir -p "$CBMPC_HOME"
  sudo git clone https://github.com/coinbase/cb-mpc.git "$REPO_DIR"
  sudo chown -R "$(id -u):$(id -g)" "$REPO_DIR"
fi
# Test: repository exists
[ -d "$REPO_DIR/.git" ]

cd "$REPO_DIR"
# Ensure submodules fetched (if any)
git submodule update --init --recursive
# Test: presence of Cargo.toml indicates repository ready
[ -f Cargo.toml ]

# Build core cb-mpc library first to ensure sources are compiled
cargo build --release -p cb-mpc
# Test: core library built
[ -f target/release/libcb_mpc.rlib ]

# Build FFI library that ServerB links against
cargo build --release -p cb-mpc-ffi
# Test: FFI library built
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
