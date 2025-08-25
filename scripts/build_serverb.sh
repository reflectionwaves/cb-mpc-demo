#!/usr/bin/env bash
set -euo pipefail

CBMPC_PREFIX=${CBMPC_HOME:-/usr/local/opt/cbmpc}
echo "CBMPC_PREFIX set to $CBMPC_PREFIX" >&2

# Determine include and library paths. Support three layouts:
# 1) an installed prefix with include/ and lib/ (or lib64/) directories,
# 2) a source checkout provided directly via CBMPC_HOME containing
#    ffi/c/include and target/release, or
# 3) a checkout nested under <prefix>/cb-mpc with the same structure.
if [ -d "$CBMPC_PREFIX/include" ] && [ -d "$CBMPC_PREFIX/lib" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/include"
  CBMPC_LIB="$CBMPC_PREFIX/lib"
elif [ -d "$CBMPC_PREFIX/include" ] && [ -d "$CBMPC_PREFIX/lib64" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/include"
  CBMPC_LIB="$CBMPC_PREFIX/lib64"
elif [ -d "$CBMPC_PREFIX/ffi/c/include" ] && [ -d "$CBMPC_PREFIX/target/release" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/ffi/c/include"
  CBMPC_LIB="$CBMPC_PREFIX/target/release"
elif [ -d "$CBMPC_PREFIX/cb-mpc/ffi/c/include" ] && [ -d "$CBMPC_PREFIX/cb-mpc/target/release" ]; then
  CBMPC_INCLUDE="$CBMPC_PREFIX/cb-mpc/ffi/c/include"
  CBMPC_LIB="$CBMPC_PREFIX/cb-mpc/target/release"
fi

if [ -z "${CBMPC_INCLUDE:-}" ] || [ -z "${CBMPC_LIB:-}" ]; then
  echo "cb-mpc not found under $CBMPC_PREFIX. Did you run scripts/install_cbmpc.sh?" >&2
  ls -al "$CBMPC_PREFIX" >&2 || true
  exit 1
fi

echo "Using CBMPC include: $CBMPC_INCLUDE" >&2
echo "Using CBMPC lib: $CBMPC_LIB" >&2

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
