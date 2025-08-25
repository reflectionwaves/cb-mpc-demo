#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}

# Determine where the cb-mpc library artifacts live. Support both an
# installed layout with lib/include directories and a source checkout
# where the build artifacts reside in target/release and headers under
# ffi/c/include.
if [ -d "$CBMPC_HOME/lib" ]; then
  libdir="$CBMPC_HOME/lib"
elif [ -d "$CBMPC_HOME/lib64" ]; then
  libdir="$CBMPC_HOME/lib64"
elif [ -d "$CBMPC_HOME/target/release" ]; then
  libdir="$CBMPC_HOME/target/release"
elif [ -d "$CBMPC_HOME/cb-mpc/target/release" ]; then
  CBMPC_HOME="$CBMPC_HOME/cb-mpc"
  libdir="$CBMPC_HOME/target/release"
else
  echo "cb-mpc libraries not found under $CBMPC_HOME" >&2
  exit 1
fi

export CBMPC_HOME
export LD_LIBRARY_PATH="$libdir:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="$libdir/pkgconfig:${PKG_CONFIG_PATH:-}"

# Tests: print variables to confirm
[ -d "$CBMPC_HOME" ]
[ -d "$libdir" ]
[ -n "$LD_LIBRARY_PATH" ]
[ -n "$PKG_CONFIG_PATH" ]

echo "CBMPC_HOME=$CBMPC_HOME"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
