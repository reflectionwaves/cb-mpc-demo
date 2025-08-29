# Build & Run (cb-mpc-demo)

This demo expects **cb-mpc** to be installed (e.g., via `sudo make install` in the cb-mpc repo)
and **OpenSSL 3.2.0 (static)** at `/usr/local/opt/openssl@3.2.0`.

## Build
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"


If your prefixes differ:

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/path/to/cbmpc \
  -DOPENSSL_ROOT_DIR=/path/to/openssl


Optionally, if your demo includes internal headers from the cb-mpc source tree, set:

export CBMPC_SOURCE_DIR=$HOME/cb-mpc/src

Binaries

build/ServerA/mpc_partyA

build/ServerB/mpc_partyB
```
