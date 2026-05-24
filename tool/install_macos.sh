#!/usr/bin/env bash
# Build MiniTerminal for macOS and install it into /Applications.
#
# Prereqs: Flutter SDK on PATH, Xcode + Command Line Tools, CocoaPods.
# Run from the repo root:  bash tool/install_macos.sh
set -euo pipefail

echo "==> Preparing project (generates macos/ + applies patches)"
bash tool/setup_local.sh

echo "==> Building macOS release app"
flutter build macos --release

APP=$(ls -d build/macos/Build/Products/Release/*.app | head -1)
if [ -z "$APP" ]; then
  echo "ERROR: built .app not found" >&2
  exit 1
fi

echo "==> Installing $APP to /Applications"
rm -rf "/Applications/MiniTerminal.app"
cp -R "$APP" "/Applications/MiniTerminal.app"

cat <<'EOF'

Done! MiniTerminal is now in /Applications (and Launchpad).

First launch (ad-hoc signed): right-click the app -> Open -> confirm
once. After that, double-click as usual.

To update later after pulling new code: run this script again.
EOF
