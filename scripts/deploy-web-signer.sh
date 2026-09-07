#!/usr/bin/env bash
# Upload website + bootstrap signer (custom IPA uploads) without rebuilding zsign.
#
#   bash scripts/deploy-web-signer.sh
#   VPS=root@158.220.85.245 bash scripts/deploy-web-signer.sh
#
set -euo pipefail

VPS="${VPS:-root@158.220.85.245}"
DOMAIN="${DOMAIN:-defiancesign.com}"
REMOTE_STAGE="/tmp/defiancesign-deploy"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Upload website + bootstrap signer to $VPS"
ssh "$VPS" "mkdir -p '$REMOTE_STAGE/website' '$REMOTE_STAGE/services/bootstrap-signer'"
rsync -avz --delete \
  --exclude '.DS_Store' \
  --exclude 'api/README.md' \
  "$ROOT/website/" "$VPS:$REMOTE_STAGE/website/"
rsync -avz --exclude '__pycache__' --exclude '.git' \
  "$ROOT/services/bootstrap-signer/" "$VPS:$REMOTE_STAGE/services/bootstrap-signer/"

echo "==> Install on VPS (website + API restart, no zsign rebuild)"
ssh "$VPS" DOMAIN="$DOMAIN" REPO_STAGE="$REMOTE_STAGE" bash -s <<'REMOTE'
set -euo pipefail
DOMAIN="${DOMAIN:-defiancesign.com}"
REPO_STAGE="${REPO_STAGE:-/tmp/defiancesign-deploy}"
STAGE="/opt/defiancesign-bootstrap"
UNIT="/etc/systemd/system/defiancesign-bootstrap.service"

[[ -d "$STAGE/app" ]] || { echo "Bootstrap signer is not installed at $STAGE. Run scripts/deploy-qadbak.sh first." >&2; exit 1; }

USER=""
for hint in /home/*/.qadbak-domain; do
  [[ -f "$hint" ]] || continue
  if [[ "$(tr -d '\r\n' <"$hint" | head -1)" == "$DOMAIN" ]]; then
    USER="$(basename "$(dirname "$hint")")"
    break
  fi
done
if [[ -z "$USER" ]]; then
  for guess in defiancesign maplesign; do
    if id "$guess" &>/dev/null && [[ -d "/home/${guess}/public_html" ]]; then
      USER="$guess"
      break
    fi
  done
fi
[[ -n "$USER" ]] || { echo "Could not resolve unix user for $DOMAIN" >&2; exit 1; }
PUB="/home/${USER}/public_html"

echo "==> Sync static website to $PUB"
rsync -a --delete --exclude '.DS_Store' --exclude 'DefianceSign.ipa' \
  "$REPO_STAGE/website/" "$PUB/"
chown -R "${USER}:${USER}" "$PUB"

echo "==> Update bootstrap signer"
rsync -a --delete --exclude '__pycache__' "$REPO_STAGE/services/bootstrap-signer/" "$STAGE/app/"
install -m 644 "$REPO_STAGE/services/bootstrap-signer/ops/defiancesign-bootstrap.service" "$UNIT"
sed -i "s|Environment=BOOTSTRAP_PUBLIC_URL=.*|Environment=BOOTSTRAP_PUBLIC_URL=https://${DOMAIN}|" "$UNIT"

systemctl daemon-reload
systemctl restart defiancesign-bootstrap

# Large IPA uploads + zsign can exceed the default 90s proxy timeout.
for conf in /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* /etc/nginx/conf.d/*.conf; do
  [[ -f "$conf" ]] || continue
  if grep -q "location /api/" "$conf"; then
    sed -i "s/proxy_read_timeout 90s;/proxy_read_timeout 600s;/g; s/proxy_send_timeout 90s;/proxy_send_timeout 600s;/g" "$conf"
  fi
done
if nginx -t >/dev/null 2>&1; then
  systemctl reload nginx || true
fi

ok=0
for i in 1 2 3 4 5 6 7 8; do
  sleep 2
  if curl -fsS http://127.0.0.1:8788/health; then
    echo ""
    ok=1
    break
  fi
done
if [[ "$ok" -ne 1 ]]; then
  echo "Service did not become healthy on :8788" >&2
  systemctl status defiancesign-bootstrap --no-pager -l || true
  journalctl -u defiancesign-bootstrap -n 60 --no-pager || true
  exit 1
fi
REMOTE

echo ""
echo "Done:"
echo "  https://${DOMAIN}/install.html"
echo "  Upload .p12 + .mobileprovision + any .ipa, then download the signed IPA."
