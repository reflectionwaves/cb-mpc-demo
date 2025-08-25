#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

CBMPC_DIR="${CBMPC_DIR:-$HOME/cb-mpc}"
CBMPC_PREFIX="${CBMPC_PREFIX:-/usr/local/opt/cbmpc}"

export CGO_CFLAGS="${CGO_CFLAGS:- -I${CBMPC_PREFIX}/include }"
export CGO_LDFLAGS="${CGO_LDFLAGS:- -L${CBMPC_PREFIX}/lib -lcbmpc -lssl -lcrypto -lm -ldl -lpthread }"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-${CBMPC_PREFIX}/lib}"

EXAMPLE_DIR="${CBMPC_DIR}/demos-go/examples/ecdsa-mpc-with-backup"
if [[ ! -d "${EXAMPLE_DIR}" ]]; then
  echo "Cannot find ${EXAMPLE_DIR}. Did you clone the cb-mpc repo?" >&2
  exit 1
fi
( cd "${EXAMPLE_DIR}" && go run . "$@" )
