#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}
export CBMPC_HOME
export LD_LIBRARY_PATH="$CBMPC_HOME/lib:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="$CBMPC_HOME/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Tests: print variables to confirm
[ -d "$CBMPC_HOME" ]
[ -n "$LD_LIBRARY_PATH" ]
[ -n "$PKG_CONFIG_PATH" ]

echo "CBMPC_HOME=$CBMPC_HOME"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
