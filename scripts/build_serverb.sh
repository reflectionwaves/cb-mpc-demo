#!/usr/bin/env bash
set -euo pipefail

CBMPC_PREFIX=${CBMPC_HOME:-/usr/local/opt/cbmpc}

# Determine include and library paths. Prefer the installed layout where
# headers live under <prefix>/include and libraries under <prefix>/lib. If that
# structure is missing, fall back to a built source tree in <prefix>/cb-mpc.
if [ -d "$CBMPC_PREFIX/include" ] && [ -d "$CBMPC_PREFIX/lib" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/include"
  CBMPC_LIB="$CBMPC_PREFIX/lib"
elif [ -d "$CBMPC_PREFIX/cb-mpc/ffi/c/include" ] \
  && [ -d "$CBMPC_PREFIX/cb-mpc/target/release" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/cb-mpc/ffi/c/include"
  CBMPC_LIB="$CBMPC_PREFIX/cb-mpc/target/release"
else
  echo "cb-mpc not found under $CBMPC_PREFIX. Did you run scripts/install_cbmpc.sh?" >&2
  exit 1
fi

echo "Using CBMPC from $CBMPC_PREFIX"

# Create build directory
mkdir -p build
[ -d build ]

# Compile ServerB
pkg_config_cflags=$(pkg-config --cflags libcurl)
pkg_config_libs=$(pkg-config --libs libcurl)

g++ -std=c++17 ServerB/mpc_partyB.cpp ServerB/http_transport.cpp \
    -I"$CBMPC_INCLUDE" $pkg_config_cflags \
    -L"$CBMPC_LIB" -lcbmpc $pkg_config_libs \
    -o build/mpc_partyB
# Test: binary exists
[ -x build/mpc_partyB ]

echo "ServerB built: build/mpc_partyB"
