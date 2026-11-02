#!/bin/zsh
# Build SnapMark.app  →  ./build.sh   (add --install to copy into ~/Applications)
set -e
cd "$(dirname "$0")"
APP=build/SnapMark.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>SnapMark</string>
  <key>CFBundleDisplayName</key><string>SnapMark</string>
  <key>CFBundleIdentifier</key><string>local.snapmark</string>
  <key>CFBundleExecutable</key><string>SnapMark</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

swiftc -O -swift-version 5 main.swift -o "$APP/Contents/MacOS/SnapMark" -framework Cocoa -framework Carbon
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "$1" == "--install" ]]; then
  mkdir -p ~/Applications
  rm -rf ~/Applications/SnapMark.app
  cp -R "$APP" ~/Applications/
  echo "Installed to ~/Applications/SnapMark.app"
fi
