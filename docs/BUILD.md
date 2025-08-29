# Build & Run (cb-mpc-demo)

This demo expects **cb-mpc** to be installed (e.g., via `sudo make install` from the cb-mpc repo)
and **OpenSSL 3.2.0 (static)** at `/usr/local/opt/openssl@3.2.0`.

## Build
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
```

If your prefixes differ:
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/path/to/cbmpc \
  -DOPENSSL_ROOT_DIR=/path/to/openssl
```

## Binaries
- `build/ServerA/mpc_partyA`
- `build/ServerB/mpc_partyB`
