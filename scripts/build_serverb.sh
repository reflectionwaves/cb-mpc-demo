#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}
# Ensure cb-mpc installation exists and fail with a helpful message otherwise
if [ ! -d "$CBMPC_HOME/include" ] || [ ! -d "$CBMPC_HOME/lib" ]; then
  echo "cb-mpc not found under $CBMPC_HOME. Did you run scripts/install_cbmpc.sh?" >&2
  exit 1
fi

echo "Using CBMPC from $CBMPC_HOME"

# Create build directory
mkdir -p build
[ -d build ]

# Compile ServerB
pkg_config_cflags=$(pkg-config --cflags libcurl)
pkg_config_libs=$(pkg-config --libs libcurl)

g++ -std=c++17 ServerB/mpc_partyB.cpp ServerB/http_transport.cpp \
    -I"$CBMPC_HOME/include" $pkg_config_cflags \
    -L"$CBMPC_HOME/lib" -lcbmpc $pkg_config_libs \
    -o build/mpc_partyB
# Test: binary exists
[ -x build/mpc_partyB ]

echo "ServerB built: build/mpc_partyB"
