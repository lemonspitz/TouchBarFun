#!/bin/zsh
# Builds a native Apple Silicon "TouchBarFun!.app" into ./build
set -euo pipefail
cd "$(dirname "$0")"

APP="build/TouchBarFun!.app"
rm -rf build && mkdir -p build/obj "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -swift-version 5 -target arm64-apple-macos11.0 \
  -framework AppKit -framework ServiceManagement -framework AVFoundation -framework Accelerate \
  Sources/*.swift -o build/obj/TouchBarFun-arm64
cp build/obj/TouchBarFun-arm64 "$APP/Contents/MacOS/TouchBarFun"

# App icon rendered from the pixel-art dog.
ICONSET=build/obj/AppIcon.iconset
mkdir -p "$ICONSET"
build/obj/TouchBarFun-arm64 --icon build/obj
for s in 16 32 128 256 512; do
  cp "build/obj/icon_$s.png" "$ICONSET/icon_${s}x${s}.png"
  cp "build/obj/icon_$((s * 2)).png" "$ICONSET/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>TouchBarFun</string>
  <key>CFBundleIdentifier</key><string>com.lemonspitz.touchbarfun</string>
  <key>CFBundleName</key><string>TouchBarFun!</string>
  <key>CFBundleDisplayName</key><string>TouchBarFun!</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>NSHumanReadableCopyright</key><string>Made by @lemonspitz · github.com/lemonspitz</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Built $APP"
