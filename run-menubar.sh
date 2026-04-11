#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="LocalhostWatcher"
APP_BINARY="$ROOT_DIR/.build/debug/$APP_NAME"
APP_BUNDLE="$ROOT_DIR/.build/debug/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS_DIR="$APP_CONTENTS/MacOS"
APP_RESOURCES_DIR="$APP_CONTENTS/Resources"
APP_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_SOURCE="$ROOT_DIR/Sources/$APP_NAME/Resources/AppIcon.icns"
APP_ICON_DEST="$APP_RESOURCES_DIR/AppIcon.icns"
RESOURCE_BUNDLE_NAME="${APP_NAME}_${APP_NAME}.bundle"
LOG_FILE="/tmp/${APP_NAME}.log"

cd "$ROOT_DIR"

echo "Building $APP_NAME..."
swift build

echo "Preparing app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS_DIR"
mkdir -p "$APP_RESOURCES_DIR"
cp "$APP_BINARY" "$APP_MACOS_DIR/$APP_NAME"
cp "$APP_ICON_SOURCE" "$APP_ICON_DEST"

RESOURCE_BUNDLE_SOURCE="$(find "$ROOT_DIR/.build" -maxdepth 4 -name "$RESOURCE_BUNDLE_NAME" -print -quit)"
if [[ -n "${RESOURCE_BUNDLE_SOURCE:-}" ]]; then
  cp -R "$RESOURCE_BUNDLE_SOURCE" "$APP_RESOURCES_DIR/$RESOURCE_BUNDLE_NAME"
fi

cat >"$APP_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>local.$APP_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "Stopping existing $APP_NAME instance..."
  pkill -x "$APP_NAME" || true
  sleep 1
fi

echo "Launching $APP_NAME..."
nohup open "$APP_BUNDLE" >"$LOG_FILE" 2>&1 &

echo "$APP_NAME launched."
echo "Log: $LOG_FILE"
