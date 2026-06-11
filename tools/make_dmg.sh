#!/bin/bash
# Builds a Release Unquarantine.app and packages it into a drag-to-install .dmg.
# Ad-hoc signed (no Developer ID / notarization) — works on this Mac; other Macs
# will hit Gatekeeper on first open.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building Release"
xcodebuild -project Unquarantine.xcodeproj -scheme Unquarantine \
    -configuration Release -derivedDataPath build clean build

APP="$ROOT/build/Build/Products/Release/Unquarantine.app"
[ -d "$APP" ] || { echo "error: app not found at $APP" >&2; exit 1; }

echo "==> Staging disk image contents"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating dmg"
mkdir -p "$ROOT/dist"
rm -f "$ROOT/dist/Unquarantine.dmg"
hdiutil create -volname "Unquarantine" -srcfolder "$STAGING" \
    -ov -format UDZO "$ROOT/dist/Unquarantine.dmg"

rm -rf "$STAGING"
echo "==> Done: dist/Unquarantine.dmg"
