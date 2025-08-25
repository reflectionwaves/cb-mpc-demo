#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Load env if present
if [[ -f ./env ]]; then
  source ./env
else
  echo "[i] No ./env present; using defaults from env.sample (copy and edit as needed)."
  source ./env.sample
fi

echo "[1/6] Installing prerequisites..."
sudo bash ./scripts/00-install-prereqs.sh

echo "[2/6] Cloning coinbase/cb-mpc..."
bash ./scripts/10-clone-cbmpc.sh

echo "[3/6] Building and installing cb-mpc..."
bash ./scripts/20-build-install-cbmpc.sh

echo "[4/6] Cloning your demo repo..."
bash ./scripts/30-clone-demo.sh

echo "[5/6] Building your demo (best-effort)..."
bash ./scripts/40-build-demo.sh || true

echo "[6/6] Smoke test..."
bash ./scripts/50-smoke-test.sh || true

cat <<'EOF'

✅ Bootstrap complete.

Next steps (examples):
  ./run/run-cbmpc-tests.sh
  ./run/run-demo.sh

If you want this to run on boot, review systemd/cbmpc-demo.service and install it:
  sudo cp systemd/cbmpc-demo.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now cbmpc-demo

EOF
