#!/usr/bin/env bash
# Check if your .p12 + .mobileprovision can install DefianceSign
# Usage: ./scripts/check-cert.sh my.p12 my.mobileprovision [p12-password]

set -euo pipefail

P12="${1:?Usage: check-cert.sh certificate.p12 profile.mobileprovision [password]}"
PROV="${2:?Usage: check-cert.sh certificate.p12 profile.mobileprovision [password]}"
PASS="${3:-}"

echo "=== DefianceSign certificate check ==="
echo ""

if [[ ! -f "$P12" ]]; then echo "ERROR: .p12 not found: $P12"; exit 1; fi
if [[ ! -f "$PROV" ]]; then echo "ERROR: .mobileprovision not found: $PROV"; exit 1; fi

echo "--- Provisioning profile ---"
PLIST=$(security cms -D -i "$PROV" 2>/dev/null || true)
if [[ -z "$PLIST" ]]; then echo "ERROR: cannot read .mobileprovision"; exit 1; fi

echo "$PLIST" | plutil -extract Name raw -o - - 2>/dev/null | xargs -I{} echo "Profile name: {}"
echo "$PLIST" | plutil -extract TeamName raw -o - - 2>/dev/null | xargs -I{} echo "Team: {}"
echo "$PLIST" | plutil -extract ExpirationDate raw -o - - 2>/dev/null | xargs -I{} echo "Expires: {}"

APP_IDS=$(echo "$PLIST" | plutil -extract ProvisionedDevices raw -o - - 2>/dev/null && echo "$PLIST" | plutil -p - 2>/dev/null | grep -A50 "Entitlements" | grep "application-identifier" | head -1 || true)
BUNDLE=$(echo "$PLIST" | plutil -p - 2>/dev/null | grep "application-identifier" | head -1 | sed 's/.*"\(.*\)".*/\1/' | sed 's/^[^.]*\.//')

echo "App ID in profile: ${BUNDLE:-unknown}"
echo ""

if echo "$BUNDLE" | grep -q "net.defiancesign.app"; then
  echo "OK: profile includes net.defiancesign.app"
else
  echo "WARNING: profile does NOT include net.defiancesign.app"
  echo "  → Create App ID 'net.defiancesign.app' on developer.apple.com"
  echo "  → OR change bundle ID to '$BUNDLE' when signing in ESign"
fi

DEVICE_COUNT=$(echo "$PLIST" | plutil -extract ProvisionedDevices json -o - - 2>/dev/null | plutil -convert json -o - - 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo 0)
echo "Devices in profile: $DEVICE_COUNT"
if [[ "$DEVICE_COUNT" == "0" ]]; then
  echo "WARNING: no devices in profile (Distribution profile?)"
  echo "  → Use 'iOS App Development' profile with your iPad UDID"
fi

echo ""
echo "--- Certificate (.p12) ---"
if [[ -n "$PASS" ]]; then
  if openssl pkcs12 -in "$P12" -noout -passin "pass:$PASS" 2>/dev/null; then
    echo "OK: .p12 password is correct"
  else
    echo "ERROR: wrong .p12 password or corrupt file"
    exit 1
  fi
else
  echo "Skip password check (pass password as 3rd argument)"
fi

echo ""
echo "=== DefianceSign needs ==="
echo "  Bundle ID: net.defiancesign.app"
echo "  IPA:       https://github.com/macdirtycow/DefianceSign/releases/latest"
echo "  After install: Settings → General → VPN & Device Management → Trust"
