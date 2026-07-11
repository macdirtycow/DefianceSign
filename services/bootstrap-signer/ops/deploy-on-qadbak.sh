#!/usr/bin/env bash
# Run ON the Qadbak VPS as root after files are uploaded.
#
#   sudo DOMAIN=defiancesign.com bash /opt/defiancesign-bootstrap/deploy-on-qadbak.sh
#
set -euo pipefail

DOMAIN="${DOMAIN:-defiancesign.com}"
QADBAK_DIR="${QADBAK_DIR:-/opt/qadbak}"
STAGE="${STAGE:-/opt/defiancesign-bootstrap}"
PORT="${BOOTSTRAP_PORT:-8788}"
REPO_STAGE="${REPO_STAGE:-/tmp/defiancesign-deploy}"

[[ "$(id -u)" -eq 0 ]] || {
  echo "Run as root: sudo bash $0" >&2
  exit 1
}

resolve_unix_user() {
  local u=""
  if [[ -n "${DEFIANCE_UNIX_USER:-}" ]]; then
    echo "$DEFIANCE_UNIX_USER"
    return 0
  fi
  local hint
  for hint in /home/*/.qadbak-domain; do
    [[ -f "$hint" ]] || continue
    if [[ "$(tr -d '\r\n' <"$hint" | head -1)" == "$DOMAIN" ]]; then
      basename "$(dirname "$hint")"
      return 0
    fi
  done
  local reg="$QADBAK_DIR/data/native-domains.json"
  if [[ -f "$reg" ]] && command -v jq &>/dev/null; then
    u="$(jq -r --arg d "$DOMAIN" '.[] | select(.name==$d) | .user' "$reg" 2>/dev/null | head -1)"
    [[ -n "$u" && "$u" != "null" ]] && echo "$u" && return 0
  fi
  for guess in defiancesign maplesign; do
    if id "$guess" &>/dev/null && [[ -d "/home/${guess}/public_html" ]]; then
      echo "$guess"
      return 0
    fi
  done
  echo "${DOMAIN%%.*}"
}

USER="$(resolve_unix_user)"
PUB="/home/${USER}/public_html"
PROXY_DIR="$QADBAK_DIR/data/domain-config/${DOMAIN}"
PROXY_JSON="$PROXY_DIR/proxies.json"

echo "==> Domain: $DOMAIN (unix user: $USER)"
echo "==> public_html: $PUB"

install -d -m 755 "$PUB"
if [[ -d "$REPO_STAGE/website" ]]; then
  echo "==> Sync static website"
  rsync -a --delete \
    --exclude '.DS_Store' \
    "$REPO_STAGE/website/" "$PUB/"
  chown -R "${USER}:${USER}" "$PUB"
fi

echo "==> Build/install zsign (always rebuild when source is present)"
if [[ -d "$REPO_STAGE/Zsign" ]]; then
  apt-get update -qq
  apt-get install -y -qq build-essential libssl-dev libminizip-dev pkg-config git python3 python3-venv python3-pip rsync jq
  make -C "$REPO_STAGE/Zsign/build/linux" -j"$(nproc)"
  install -m755 "$REPO_STAGE/Zsign/bin/zsign" /usr/local/bin/zsign
elif ! command -v zsign &>/dev/null; then
  echo "ERR: Zsign source missing at $REPO_STAGE/Zsign and no system zsign" >&2
  exit 1
fi
zsign -v | head -1

echo "==> Install bootstrap API to $STAGE"
install -d -m 700 "$STAGE" /var/lib/defiancesign-bootstrap/work
rsync -a --delete "$REPO_STAGE/services/bootstrap-signer/" "$STAGE/app/"
cp "$REPO_STAGE/services/bootstrap-signer/ops/defiancesign-bootstrap.service" /etc/systemd/system/

python3 -m venv "$STAGE/venv"
"$STAGE/venv/bin/pip" install -q -r "$STAGE/app/requirements.txt"

sed -i "s|Environment=BOOTSTRAP_PUBLIC_URL=.*|Environment=BOOTSTRAP_PUBLIC_URL=https://${DOMAIN}|" /etc/systemd/system/defiancesign-bootstrap.service
sed -i "s|--port 8788|--port ${PORT}|" /etc/systemd/system/defiancesign-bootstrap.service

systemctl daemon-reload
systemctl enable defiancesign-bootstrap
systemctl restart defiancesign-bootstrap
sleep 1
curl -fsS "http://127.0.0.1:${PORT}/health" | head -c 200
echo ""

echo "==> Configure nginx reverse proxy /api → :${PORT}"
install -d -m 755 "$PROXY_DIR"
cp "$REPO_STAGE/services/bootstrap-signer/ops/qadbak-proxies.json" "$PROXY_JSON"

if [[ -f "$QADBAK_DIR/scripts/apply-domain-nginx.sh" ]]; then
  bash "$QADBAK_DIR/scripts/apply-domain-nginx.sh" "$DOMAIN" "$USER"
else
  echo "WARN: apply-domain-nginx.sh not found — add proxy manually" >&2
fi

echo ""
echo "OK — https://${DOMAIN}/install.html"
echo "API health: https://${DOMAIN}/api/bootstrap/sign (POST only)"
echo "Test: curl -fsS https://${DOMAIN}/api/../health 2>/dev/null || curl -fsS http://127.0.0.1:${PORT}/health"
