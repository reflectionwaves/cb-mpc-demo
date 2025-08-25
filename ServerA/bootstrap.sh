#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Load env (prefer ./env, fallback to ./env.sample)
if [[ -f ./env ]]; then
  source ./env
else
  echo "[i] Using defaults from env.sample (copy to ./env to customize)."
  source ./env.sample
fi

echo "[1/7] Installing prerequisites..."
sudo bash ./scripts/00-install-prereqs.sh

echo "[2/7] Cloning coinbase/cb-mpc..."
bash ./scripts/10-clone-cbmpc.sh

echo "[3/7] Ensuring static OpenSSL ${OPENSSL_VER} exists (BUILD_STATIC_OPENSSL=${BUILD_STATIC_OPENSSL})..."
bash ./scripts/05-build-static-openssl.sh

echo "[4/7] Building and installing cb-mpc..."
bash ./scripts/20-build-install-cbmpc.sh

echo "[5/7] Cloning your demo repo..."
bash ./scripts/30-clone-demo.sh

echo "[6/7] Building your demo (best-effort)..."
bash ./scripts/40-build-demo.sh || true

echo "[7/7] Smoke test..."
bash ./scripts/50-smoke-test.sh || true

cat <<'EOF'

✅ Bootstrap complete.

Next steps:
  ./run/run-cbmpc-tests.sh
  ./run/run-demo.sh

If you want this to run on boot:
  sudo cp systemd/cbmpc-demo.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now cbmpc-demo

EOF
