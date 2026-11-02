#!/bin/zsh
# Build SnapMark.app (universal: Apple Silicon + Intel)
#   ./build.sh            → build/SnapMark.app
#   ./build.sh --install  → also copy into ~/Applications
#   ./build.sh --dmg      → also create dist/SnapMark.dmg
set -e
cd "$(dirname "$0")"
VERSION=1.0
APP=build/SnapMark.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>SnapMark</string>
  <key>CFBundleDisplayName</key><string>SnapMark</string>
  <key>CFBundleIdentifier</key><string>local.snapmark</string>
  <key>CFBundleExecutable</key><string>SnapMark</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -target $arch-apple-macos12 main.swift -o build/SnapMark-$arch \
    -framework Cocoa -framework Carbon
done
lipo -create build/SnapMark-arm64 build/SnapMark-x86_64 -output "$APP/Contents/MacOS/SnapMark"
rm build/SnapMark-arm64 build/SnapMark-x86_64
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "$1" == "--install" ]]; then
  mkdir -p ~/Applications
  rm -rf ~/Applications/SnapMark.app
  cp -R "$APP" ~/Applications/
  echo "Installed to ~/Applications/SnapMark.app"
fi

if [[ "$1" == "--dmg" ]]; then
  STAGE=build/dmg
  rm -rf "$STAGE" && mkdir -p "$STAGE" dist
  cp -R "$APP" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  rm -f dist/SnapMark.dmg
  hdiutil create -volname "SnapMark $VERSION" -srcfolder "$STAGE" -ov -format UDZO dist/SnapMark.dmg >/dev/null
  rm -rf "$STAGE"
  echo "Created dist/SnapMark.dmg"
fi
