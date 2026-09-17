#!/usr/bin/env bash
# Builds a macOS .dmg containing the app bundle and an /Applications shortcut,
# so the user can drag the app into Applications from the mounted image.
#
# Usage: make_dmg.sh <version>   # e.g. make_dmg.sh v1.1.6
set -euo pipefail

VERSION="${1:?usage: make_dmg.sh <version>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/build/macos/Build/Products/Release/网站屏蔽检测.app"
STAGE="$ROOT/build/dmg"
OUT="$ROOT/../EFH-$VERSION-macos.dmg"

[[ -d "$APP" ]] || { echo "missing app: $APP (run: flutter build macos --release)" >&2; exit 1; }

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$OUT"
hdiutil create -volname "网站屏蔽检测" -srcfolder "$STAGE" -ov -format UDZO "$OUT"
echo "wrote $OUT"
