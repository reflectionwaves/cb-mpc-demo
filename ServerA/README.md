# cb-mpc demo bootstrap (with static OpenSSL) — Server A

This bundle sets up Ubuntu 24.04.3 LTS to build and run **cb-mpc** with a **static OpenSSL 3.2.0** under `/usr/local/opt/openssl@3.2.0`. Then it builds your **cb-mpc-demo**.

## TL;DR
```bash
unzip serverA-bundle-v2.zip
cd serverA-bundle-v2
cp env.sample env   # and edit PEER_HOST
./bootstrap.sh
```

Try afterwards:
```bash
./run/run-cbmpc-tests.sh
./run/run-demo.sh
```

### What changed vs v1?
- Adds a **reliable, host-level** build of **OpenSSL 3.2.0 (static)** in `scripts/openssl/`.
- Bootstrap now **builds OpenSSL first** (idempotent), then builds `cb-mpc` with the correct OpenSSL path.
- `20-build-install-cbmpc.sh` now **cleans the previous CMake build** and exports `OPENSSL_ROOT_DIR` so CMake finds the static libs.

## File tree
```
serverA-bundle-v2/
  bootstrap.sh
  env.sample
  scripts/
    00-install-prereqs.sh
    05-build-static-openssl.sh
    openssl/build-static-openssl-linux.sh
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

## Quick role config

Defaults to role **A**. Edit `env` as needed:

```bash
ROLE="A"
SELF_HOST="0.0.0.0"
SELF_PORT="7001"
PEER_HOST="<peer-ip-or-dns>"
PEER_PORT="7002"

# OpenSSL / toolchain
OPENSSL_VER="3.2.0"
BUILD_STATIC_OPENSSL="yes"   # set "no" to skip (requires matching OpenSSL already installed)
LLVM_VERSION="20"
```

### Systemd
To run on boot:
```bash
sudo cp systemd/cbmpc-demo.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cbmpc-demo
```
