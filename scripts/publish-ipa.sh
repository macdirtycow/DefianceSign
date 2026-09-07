#!/usr/bin/env bash
# Build or fetch DefianceSign.ipa, then upload it to defiancesign.com from your Mac.
#
# Usage:
#   bash scripts/publish-ipa.sh
#   IPA=~/Downloads/DefianceSign.ipa bash scripts/publish-ipa.sh
#   VPS=root@158.220.85.245 bash scripts/publish-ipa.sh
#
set -euo pipefail

VPS="${VPS:-root@158.220.85.245}"
DOMAIN="${DOMAIN:-defiancesign.com}"
REMOTE_STAGE="/tmp/defiancesign-deploy"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA_DEST="$ROOT/packages/DefianceSign.ipa"
REPO="${GITHUB_REPO:-macdirtycow/DefianceSign}"

obtain_ipa() {
  if [[ -n "${IPA:-}" ]]; then
    [[ -f "$IPA" ]] || { echo "IPA not found: $IPA" >&2; exit 1; }
    mkdir -p "$ROOT/packages"
    cp "$IPA" "$IPA_DEST"
    echo "Using $IPA"
    return
  fi

  if xcodebuild -version >/dev/null 2>&1; then
    echo "==> Building unsigned IPA with Xcode"
    bash "$ROOT/scripts/build-release.sh"
    return
  fi

  echo "==> No Xcode — downloading latest GitHub beta IPA"
  command -v gh >/dev/null 2>&1 || {
    echo "Install GitHub CLI (gh) or Xcode, or pass IPA=/path/to/DefianceSign.ipa" >&2
    exit 1
  }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  if ! gh release download beta --repo "$REPO" --pattern '*.ipa' --dir "$tmp" --clobber; then
    echo "Beta release has no IPA yet. Wait for GitHub Actions, then retry." >&2
    echo "  gh run list --repo $REPO --workflow 'Beta Build' --limit 3" >&2
    exit 1
  fi
  mkdir -p "$ROOT/packages"
  shopt -s nullglob
  downloaded=("$tmp"/*.ipa)
  [[ ${#downloaded[@]} -eq 1 ]] || { echo "Expected one IPA in beta release" >&2; exit 1; }
  mv "${downloaded[0]}" "$IPA_DEST"
}

[[ -f "$IPA_DEST" && -z "${IPA:-}" && "${REUSE_IPA:-}" == "1" ]] || obtain_ipa

[[ -f "$IPA_DEST" ]] || { echo "IPA missing at $IPA_DEST" >&2; exit 1; }
SIZE=$(du -h "$IPA_DEST" | awk '{print $1}')
echo "IPA: $IPA_DEST ($SIZE)"

echo "==> Upload IPA + bootstrap signer to $VPS"
ssh "$VPS" "mkdir -p '$REMOTE_STAGE/packages' '$REMOTE_STAGE/services/bootstrap-signer'"
rsync -avz "$IPA_DEST" "$VPS:$REMOTE_STAGE/packages/DefianceSign.ipa"
rsync -avz --exclude '__pycache__' --exclude '.git' \
  "$ROOT/services/bootstrap-signer/" "$VPS:$REMOTE_STAGE/services/bootstrap-signer/"

echo "==> Install IPA on VPS (no website overwrite, no zsign rebuild)"
ssh "$VPS" DOMAIN="$DOMAIN" REPO_STAGE="$REMOTE_STAGE" bash -s <<'REMOTE'
set -euo pipefail
DOMAIN="${DOMAIN:-defiancesign.com}"
REPO_STAGE="${REPO_STAGE:-/tmp/defiancesign-deploy}"
STAGE="/opt/defiancesign-bootstrap"
UNIT="/etc/systemd/system/defiancesign-bootstrap.service"
IPA_SRC="$REPO_STAGE/packages/DefianceSign.ipa"

[[ -f "$IPA_SRC" ]] || { echo "Uploaded IPA missing at $IPA_SRC" >&2; exit 1; }
[[ -d "$STAGE/app" ]] || { echo "Bootstrap signer is not installed at $STAGE. Run scripts/deploy-qadbak.sh first." >&2; exit 1; }

install -m 644 "$IPA_SRC" "$STAGE/DefianceSign.ipa"
rsync -a --delete --exclude '__pycache__' "$REPO_STAGE/services/bootstrap-signer/" "$STAGE/app/"
install -m 644 "$REPO_STAGE/services/bootstrap-signer/ops/defiancesign-bootstrap.service" "$UNIT"
sed -i "s|Environment=BOOTSTRAP_PUBLIC_URL=.*|Environment=BOOTSTRAP_PUBLIC_URL=https://${DOMAIN}|" "$UNIT"

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
if [[ -n "$USER" && -d "/home/${USER}/public_html" ]]; then
  install -m 644 "$STAGE/DefianceSign.ipa" "/home/${USER}/public_html/DefianceSign.ipa"
  chown "${USER}:${USER}" "/home/${USER}/public_html/DefianceSign.ipa"
  echo "Public IPA: /home/${USER}/public_html/DefianceSign.ipa"
fi

systemctl daemon-reload
systemctl restart defiancesign-bootstrap

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
echo "Done. Web installer now signs this IPA:"
echo "  https://${DOMAIN}/install.html"
echo "  https://${DOMAIN}/DefianceSign.ipa"
echo "  https://${DOMAIN}/api/health"
echo ""
echo "Open install.html in Safari on the iPhone/iPad to install the update."
