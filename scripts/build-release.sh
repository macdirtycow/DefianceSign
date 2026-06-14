#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${SCHEME:-MapleSign}"
IPA_NAME="${IPA_NAME:-DefianceSign}"
OUTPUT_DIR="$ROOT/packages"
IPA_PATH="$OUTPUT_DIR/${IPA_NAME}.ipa"

echo "DefianceSign release build"
echo "  Scheme: $SCHEME"
echo "  Output: $IPA_PATH"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode first."
  exit 1
fi

echo ""
echo "Initializing submodules..."
git submodule update --init --recursive

echo ""
echo "Building unsigned IPA (sideload-ready)..."
make clean "$IPA_NAME"

if [[ ! -f "$IPA_PATH" ]]; then
  echo "IPA not found at $IPA_PATH"
  exit 1
fi

SIZE=$(du -h "$IPA_PATH" | cut -f1)
echo ""
echo "Done: $IPA_PATH ($SIZE)"
echo ""
echo "Install DefianceSign once via Sideloadly, AltStore, or SideStore,"
echo "then use it to sign other apps with your own .p12 certificate."
