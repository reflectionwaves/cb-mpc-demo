# cb-mpc demo bootstrap — Server B

This bundle sets up a Ubuntu 24.04.3 LTS host to build and run the Coinbase **cb-mpc** library and then builds your **cb-mpc-demo** repo.

## TL;DR
```bash
unzip serverB-bundle.zip
cd serverB-bundle
# (optional) review and edit ./env if needed
cp env.sample env
# Run everything (requires sudo privileges)
./bootstrap.sh
```

When finished, try:
```bash
# Smoke tests for the library
./run/run-cbmpc-tests.sh

# If your demo produces a binary or run script, this will try to launch it.
# It auto-detects common paths like ServerA/ServerB or a generic CMake build.
./run/run-demo.sh
```

> **Notes**
> - These scripts install Clang 20 via the official LLVM apt repository, along with build tools and Go.
> - `cb-mpc` is cloned to `$HOME/cb-mpc` by default and installed to `/usr/local/opt/cbmpc`.
> - If your environment is air‑gapped, mirror the packages and repos or inline-edit the scripts.
> - The `env` file controls network and build options; update `PEER_HOST`, `SELF_HOST`, etc.

## File tree
```
serverB-bundle/
  bootstrap.sh
  env.sample
  scripts/
    00-install-prereqs.sh
    10-clone-cbmpc.sh
    20-build-install-cbmpc.sh
    30-clone-demo.sh
    40-build-demo.sh
    50-smoke-test.sh
  run/
    run-cbmpc-tests.sh
    run-go-ecdsa-mpc-with-backup.sh
    run-demo.sh
  systemd/
    cbmpc-demo.service
  README.md
```

## What the scripts do

1. **00-install-prereqs.sh** — Installs Clang 20, CMake, Make, Go, Git, and other build tools; configures the LLVM apt repo.
2. **10-clone-cbmpc.sh** — Clones `coinbase/cb-mpc` into `$HOME/cb-mpc` and initializes submodules.
3. **20-build-install-cbmpc.sh** — Builds the library (`make build`) and installs it (`sudo make install`), then builds demos and runs tests.
4. **30-clone-demo.sh** — Clones your demo repo `reflectionwaves/cb-mpc-demo` into `$HOME/cb-mpc-demo`.
5. **40-build-demo.sh** — Tries to build your demo with CMake (Release) using Clang 20; falls back to Make or Go if detected.
6. **50-smoke-test.sh** — Runs a quick smoke test (`make test`) to verify the installation.
7. **run/run-demo.sh** — Heuristically finds and runs your built demo (supports ServerA/ServerB layouts and generic builds).

## Quick role config

These values live in `env.sample` (copy to `env` and edit). By default this server is **Role B**.

```bash
ROLE="B"            # A or B
SELF_HOST="0.0.0.0"      # bind address on this server
SELF_PORT="7002"      # listen port (e.g., 7001 or 7002)
PEER_HOST="<peer-ip-or-dns>"    # the other server
PEER_PORT="7001"  # the other server's port
CBMPC_DIR="$HOME/cb-mpc"
DEMO_DIR="$HOME/cb-mpc-demo"
USE_SUDO_INSTALL="yes"   # use sudo for 'make install'
```

---

If you need to tailor paths, edit the env file or tweak the scripts — they are straightforward Bash.
