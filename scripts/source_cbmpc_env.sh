#!/usr/bin/env bash
set -euo pipefail

CBMPC_HOME=${CBMPC_HOME:-/usr/local/opt/cbmpc}

# Fall back to a nested cb-mpc directory if lib/include reside there
if [ ! -d "$CBMPC_HOME/lib" ] || [ ! -d "$CBMPC_HOME/include" ]; then
  alt="$CBMPC_HOME/cb-mpc"
  if [ -d "$alt/lib" ] && [ -d "$alt/include" ]; then
    CBMPC_HOME="$alt"
  fi
fi

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
