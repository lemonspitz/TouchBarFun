#!/bin/bash
# One-line installer for TouchBarFun!:
#   curl -fsSL https://raw.githubusercontent.com/lemonspitz/TouchBarFun/main/install.sh | bash
set -euo pipefail

APP_NAME="TouchBarFun!.app"
URL="https://github.com/lemonspitz/TouchBarFun/releases/latest/download/TouchBarFun.zip"

if [ "$(uname -m)" != "arm64" ]; then
  echo "TouchBarFun! needs an Apple Silicon Mac with a Touch Bar (13-inch MacBook Pro M1 or M2)." >&2
  exit 1
fi

DEST="/Applications"
[ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading TouchBarFun!…"
curl -fsSL "$URL" -o "$TMP/TouchBarFun.zip"
ditto -x -k "$TMP/TouchBarFun.zip" "$TMP"

pkill -x TouchBarFun 2>/dev/null || true
rm -rf "$DEST/$APP_NAME"
ditto "$TMP/$APP_NAME" "$DEST/$APP_NAME"
xattr -dr com.apple.quarantine "$DEST/$APP_NAME" 2>/dev/null || true

echo "Installed to $DEST/$APP_NAME — look for 🐾 in the menu bar and on the Touch Bar."
open "$DEST/$APP_NAME"
