#!/usr/bin/env bash
# Builds a single-file Linux AppImage from the Flutter release bundle.
#
# Usage: make_appimage.sh <version>   # e.g. make_appimage.sh v1.1.6
set -euo pipefail

VERSION="${1:?usage: make_appimage.sh <version>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
WORK="$ROOT/build/appimage"
APPDIR="$WORK/AppDir"
TOOL="$WORK/appimagetool-x86_64.AppImage"
OUT="$ROOT/../EFH-$VERSION-linux-x86_64.AppImage"
ICON="$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"

[[ -d "$BUNDLE" ]] || { echo "missing bundle: $BUNDLE (run: flutter build linux --release)" >&2; exit 1; }
[[ -f "$ICON" ]] || { echo "missing icon: $ICON" >&2; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE"/. "$APPDIR/usr/bin/"
cp "$ICON" "$APPDIR/efh.png"

cat > "$APPDIR/efh.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=EFH Website Blocking Detection
Name[zh_CN]=网站屏蔽检测
Comment=Detect websites blocked by the HDSB firewall
Exec=efh_connectivity_test
Icon=efh
Categories=Network;Utility;
Terminal=false
EOF

ln -sf usr/bin/efh_connectivity_test "$APPDIR/AppRun"

if [[ ! -x "$TOOL" ]]; then
  mkdir -p "$WORK"
  curl -fsSL -o "$TOOL" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOL"
fi

# appimagetool needs FUSE; extract-and-run works on CI runners without it.
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" "$APPDIR" "$OUT"
echo "wrote $OUT"
