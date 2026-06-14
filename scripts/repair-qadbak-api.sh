#!/usr/bin/env bash
# Finish API install on VPS after website is already deployed.
# Faster than full deploy — only rebuilds zsign + restarts service.
#
#   VPS=root@158.220.85.245 bash scripts/repair-qadbak-api.sh
#
set -euo pipefail

VPS="${VPS:-root@158.220.85.245}"
DOMAIN="${DOMAIN:-defiancesign.com}"
REMOTE_STAGE="/tmp/defiancesign-deploy"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Upload fixed Zsign + bootstrap signer"
ssh "$VPS" "mkdir -p '$REMOTE_STAGE/Zsign' '$REMOTE_STAGE/services/bootstrap-signer'"
rsync -avz \
  --exclude '__pycache__' \
  "$ROOT/Zsign/src/zsign.cpp" "$VPS:$REMOTE_STAGE/Zsign/src/zsign.cpp"
rsync -avz \
  --exclude '__pycache__' \
  "$ROOT/services/bootstrap-signer/" "$VPS:$REMOTE_STAGE/services/bootstrap-signer/"

echo "==> Rebuild zsign + restart API"
ssh "$VPS" "DOMAIN='$DOMAIN' REPO_STAGE='$REMOTE_STAGE' bash '$REMOTE_STAGE/services/bootstrap-signer/ops/deploy-on-qadbak.sh'"

echo "==> Verify (retry — nginx may need a moment)"
for i in 1 2 3 4 5; do
  if curl -fsS "https://${DOMAIN}/api/health" 2>/dev/null; then
    echo ""
    exit 0
  fi
  sleep 2
done
echo "WARN: public /api/health not ready yet — API may still be OK on the VPS:" >&2
echo "  ssh $VPS curl -fsS http://127.0.0.1:8788/health" >&2
