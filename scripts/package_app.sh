#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release --product MetricsWidget
BIN_DIR="$(swift build -c release --product MetricsWidget --show-bin-path)"
BIN="$BIN_DIR/MetricsWidget"
if [[ ! -x "$BIN" ]]; then
  echo "missing release binary: $BIN" >&2
  exit 1
fi

if RAW_TAG="$(git describe --tags --exact-match HEAD 2>/dev/null)"; then
  :
elif RAW_TAG="$(git describe --tags --abbrev=0 2>/dev/null)"; then
  :
else
  RAW_TAG="1.0"
fi
VERSION="${RAW_TAG#v}"

APP_ROOT="$ROOT/build/MetricsWidget.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_ROOT"
mkdir -p "$MACOS" "$RESOURCES/Fonts"
cp "$BIN" "$MACOS/MetricsWidget"
chmod +x "$MACOS/MetricsWidget"

FONT_SRC="$ROOT/MetricsWidget/Resources/Fonts/PressStart2P-Regular.ttf"
if [[ -f "$FONT_SRC" ]]; then
  cp "$FONT_SRC" "$RESOURCES/PressStart2P-Regular.ttf"
  cp "$FONT_SRC" "$RESOURCES/Fonts/PressStart2P-Regular.ttf"
fi

shopt -s nullglob
for bundle in "$BIN_DIR/MetricsWidget_MetricsWidget.bundle" "$BIN_DIR/MetricsWidget.bundle"; do
  if [[ -d "$bundle" ]]; then
    cp -R "$bundle" "$RESOURCES/"
  fi
done
shopt -u nullglob

printf '%s' 'APPL????' > "$CONTENTS/PkgInfo"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Metrics</string>
	<key>CFBundleExecutable</key>
	<string>MetricsWidget</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.metricswidget.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>MetricsWidget</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>LSMinimumSystemVersion</key>
	<string>15.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

ICONSET="$ROOT/build/AppIcon.iconset"
rm -rf "$ICONSET"
if command -v iconutil >/dev/null 2>&1; then
  mkdir -p "$ICONSET"
  cp "$ROOT/MetricsWidget/Assets.xcassets/AppIcon.appiconset/"icon_*.png "$ICONSET/"
  if iconutil -c icns -o "$RESOURCES/AppIcon.icns" "$ICONSET"; then
    :
  else
    rm -f "$RESOURCES/AppIcon.icns"
  fi
  rm -rf "$ICONSET"
fi

codesign --force --deep -s - "$APP_ROOT"
codesign --verify --deep --strict "$APP_ROOT"

ZIP="$ROOT/build/MetricsWidget-${VERSION}.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP_ROOT" "$ZIP"

echo "Built $APP_ROOT"
echo "Zipped $ZIP"
