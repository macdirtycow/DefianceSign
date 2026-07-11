#!/usr/bin/env bash
# Upload DefianceSign website + bootstrap API to your Qadbak VPS and install.
#
# Usage (from your Mac, with SSH key to the panel VPS):
#   bash scripts/deploy-qadbak.sh
#   VPS=root@158.220.85.245 DOMAIN=defiancesign.com bash scripts/deploy-qadbak.sh
#
set -euo pipefail

VPS="${VPS:-root@158.220.85.245}"
DOMAIN="${DOMAIN:-defiancesign.com}"
REMOTE_STAGE="/tmp/defiancesign-deploy"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Upload to $VPS:$REMOTE_STAGE"
ssh "$VPS" "mkdir -p '$REMOTE_STAGE/website' '$REMOTE_STAGE/services/bootstrap-signer' '$REMOTE_STAGE/Zsign'"
rsync -avz --delete \
  --exclude '.git' \
  --exclude 'DefianceSign/' \
  --exclude 'packages/' \
  --exclude 'deps/' \
  --exclude 'Payload/' \
  --exclude 'node_modules/' \
  --exclude '.DS_Store' \
  "$ROOT/website/" "$VPS:$REMOTE_STAGE/website/"
rsync -avz \
  --exclude '__pycache__' \
  "$ROOT/services/bootstrap-signer/" "$VPS:$REMOTE_STAGE/services/bootstrap-signer/"
rsync -avz \
  --exclude 'build/linux/.build' \
  --exclude 'bin/zsign' \
  --exclude '.git' \
  "$ROOT/Zsign/" "$VPS:$REMOTE_STAGE/Zsign/"

echo "==> Install on VPS (website + API + nginx /api proxy)"
ssh "$VPS" "DOMAIN='$DOMAIN' REPO_STAGE='$REMOTE_STAGE' bash '$REMOTE_STAGE/services/bootstrap-signer/ops/deploy-on-qadbak.sh'"

echo ""
echo "Done:"
echo "  https://${DOMAIN}/"
echo "  https://${DOMAIN}/install.html"
echo ""
echo "Open install.html in Safari on your iPad to install DefianceSign without a Mac."
