# cb-mpc-demo

Example demonstrating how to build ServerB using Coinbase's [cb-mpc](https://github.com/coinbase/cb-mpc) library.

## Build scripts

The `scripts/` directory contains helper scripts:

1. `install_dependencies.sh` – installs system packages required for building and verifies they were installed.
2. `install_cbmpc.sh` – clones the `cb-mpc` repository into `$CBMPC_HOME/cb-mpc`, builds it, and installs the FFI library under `/usr/local/opt/cbmpc` by default.
3. `source_cbmpc_env.sh` – sets `CBMPC_HOME`, `LD_LIBRARY_PATH`, and `PKG_CONFIG_PATH` for the current shell.
   It works whether `cb-mpc` has been installed under a prefix with `lib/`
   and `include/` directories or if you're pointing `CBMPC_HOME` at a source
   checkout containing the built artifacts in `target/release` and headers in
   `ffi/c/include`.
4. `build_serverb.sh` – compiles `ServerB/mpc_partyB.cpp` using the locally
   installed `cb-mpc` library or directly against a built source tree.

Each command in the scripts is followed by a simple test to ensure progress.

## Usage

```bash
# Install build tools and libraries
./scripts/install_dependencies.sh

# Build and install cb-mpc
./scripts/install_cbmpc.sh

# Set environment variables for this session
source ./scripts/source_cbmpc_env.sh

# Compile ServerB
./scripts/build_serverb.sh
```

Adjust `CBMPC_HOME` if the cb-mpc library is installed in a different location,
or point it at a local `cb-mpc` checkout. The scripts automatically detect
whether the library is installed under a prefix or only built inside the
repository tree.
