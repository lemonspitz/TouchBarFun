#!/bin/zsh
# Builds TouchBarFun! and packages it for a GitHub release:
#   build/release/TouchBarFun.dmg  – open it and drag the app onto Applications
#   build/release/TouchBarFun.zip  – used by install.sh
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
OUT=build/release
STAGE=build/obj/dmg
rm -rf "$OUT" "$STAGE" && mkdir -p "$OUT" "$STAGE"

ditto -c -k --sequesterRsrc --keepParent "build/TouchBarFun!.app" "$OUT/TouchBarFun.zip"

ditto "build/TouchBarFun!.app" "$STAGE/TouchBarFun!.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -quiet -volname "TouchBarFun!" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$OUT/TouchBarFun.dmg"

(cd "$OUT" && shasum -a 256 TouchBarFun.dmg TouchBarFun.zip > SHA256SUMS.txt)
ls -lh "$OUT"
