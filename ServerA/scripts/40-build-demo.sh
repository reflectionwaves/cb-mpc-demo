#!/usr/bin/env bash
set -euo pipefail
# Best-effort builder for a repo that may contain CMake, Make, Go, or simple run scripts.
source "$(dirname "$0")/../env" 2>/dev/null || source "$(dirname "$0")/../env.sample"

DEMO_DIR="${DEMO_DIR:-$HOME/cb-mpc-demo}"
LLVM_VERSION="${LLVM_VERSION:-20}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"
CBMPC_PREFIX="${CBMPC_PREFIX:-/usr/local/opt/cbmpc}"

export CC="clang-${LLVM_VERSION}"
export CXX="clang++-${LLVM_VERSION}"
export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-${CBMPC_PREFIX}}"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-${CBMPC_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-${CBMPC_PREFIX}/lib}"
export LIBRARY_PATH="${LIBRARY_PATH:-${CBMPC_PREFIX}/lib}"

if [[ ! -d "${DEMO_DIR}" ]]; then
  echo "Demo directory ${DEMO_DIR} not found. Clone it first." >&2
  exit 0
fi

try_cmake() {
  local src="$1"
  if [[ -f "${src}/CMakeLists.txt" ]]; then
    echo "[*] Building with CMake in ${src} ..."
    cmake -S "${src}" -B "${src}/build" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER="${CC}" \
      -DCMAKE_CXX_COMPILER="${CXX}" \
      -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"
    cmake --build "${src}/build" -j"${PARALLEL_JOBS}"
    return 0
  fi
  return 1
}

try_make() {
  local src="$1"
  if [[ -f "${src}/Makefile" ]]; then
    echo "[*] Building with Make in ${src} ..."
    make -C "${src}" -j"${PARALLEL_JOBS}"
    return 0
  fi
  return 1
}

try_go() {
  local src="$1"
  if [[ -f "${src}/go.mod" ]]; then
    echo "[*] Building Go modules in ${src} ..."
    ( cd "${src}" && go build ./... || true )
    return 0
  fi
  return 1
}

# Try at repo root
try_cmake "${DEMO_DIR}" || try_make "${DEMO_DIR}" || try_go "${DEMO_DIR}" || true

# Try common subdirs
for d in "${DEMO_DIR}/ServerA" "${DEMO_DIR}/ServerB" "${DEMO_DIR}/src" "${DEMO_DIR}/app" ; do
  [[ -d "$d" ]] || continue
  try_cmake "$d" || try_make "$d" || try_go "$d" || true
done

echo "[*] Build step finished (best-effort)."
