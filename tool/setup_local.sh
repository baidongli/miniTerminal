#!/usr/bin/env bash
# Local dev bootstrap — mirrors exactly what CI does so local builds and
# CI builds stay identical. Run once after cloning (and again if you
# delete android/ ios/). Then: flutter run
#
#   bash tool/setup_local.sh
#
# macOS/Linux. Requires the Flutter SDK on PATH.
set -euo pipefail

ORG=com.baidongli

echo "==> Disabling Swift Package Manager (flutter_secure_storage is"
echo "    CocoaPods-only; SPM+Pods hybrid causes 'Module not found')"
flutter config --no-enable-swift-package-manager >/dev/null || true

echo "==> Clean-regenerating android/ ios/ (they are generated, not"
echo "    committed; flutter create does NOT overwrite existing files,"
echo "    so we wipe first to match CI's fresh checkout exactly)"
rm -rf android ios macos
flutter create --org "$ORG" --project-name miniterminal \
  --platforms=android,ios,macos .

echo "==> Patching MainActivity -> FlutterFragmentActivity (local_auth)"
find android/app/src/main -name 'MainActivity.kt' -print0 |
  while IFS= read -r -d '' f; do
    perl -pi -e \
      's/io\.flutter\.embedding\.android\.FlutterActivity/io.flutter.embedding.android.FlutterFragmentActivity/g; s/:\s*FlutterActivity\(\)/: FlutterFragmentActivity()/g' \
      "$f"
    echo "   patched $f"
  done

MAN=android/app/src/main/AndroidManifest.xml
echo "==> Ensuring INTERNET + USE_BIOMETRIC permissions in $MAN"
grep -q 'android.permission.INTERNET' "$MAN" || perl -pi -e \
  's{<application}{<uses-permission android:name="android.permission.INTERNET"/>\n    <application}' \
  "$MAN"
grep -q 'USE_BIOMETRIC' "$MAN" || perl -pi -e \
  's{<application}{<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <application}' \
  "$MAN"

echo "==> Setting display name to 'MiniTerminal'"
perl -pi -e 's/android:label="miniterminal"/android:label="MiniTerminal"/' "$MAN"
PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ]; then
  pb() { /usr/libexec/PlistBuddy -c "$1" "$PLIST" 2>/dev/null; }
  pb "Set :CFBundleDisplayName MiniTerminal" \
    || pb "Add :CFBundleDisplayName string MiniTerminal"
  # App Store review keys: encryption export compliance + permission strings
  pb "Set :ITSAppUsesNonExemptEncryption false" \
    || pb "Add :ITSAppUsesNonExemptEncryption bool false"
  pb "Set :NSFaceIDUsageDescription Unlock MiniTerminal with Face ID." \
    || pb "Add :NSFaceIDUsageDescription string Unlock MiniTerminal with Face ID."
  pb "Set :NSLocalNetworkUsageDescription MiniTerminal uses the local network to reach SSH servers on your network." \
    || pb "Add :NSLocalNetworkUsageDescription string MiniTerminal uses the local network to reach SSH servers on your network."
fi

echo "==> Configuring macOS (disable sandbox for local/Developer-ID; app name)"
# App sandbox is disabled so flutter_secure_storage (Keychain) and SSH
# networking work under ad-hoc local signing without restricted
# entitlements (-34018). Trade-off: not Mac App Store eligible — re-enable
# sandbox + proper signing/Team when targeting the Mac App Store.
if [ -d macos ]; then
  for ENT in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
    /usr/libexec/PlistBuddy -c "Set :com.apple.security.app-sandbox false" "$ENT" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :com.apple.security.app-sandbox bool false" "$ENT"
    /usr/libexec/PlistBuddy -c "Delete :keychain-access-groups" "$ENT" 2>/dev/null || true
    echo "   sandbox disabled in $ENT"
  done
  perl -pi -e 's/PRODUCT_NAME = miniterminal/PRODUCT_NAME = MiniTerminal/' \
    macos/Runner/Configs/AppInfo.xcconfig
fi

GR=android/app/build.gradle.kts
echo "==> Removing forced NDK + raising minSdk to 23 (flutter_secure_storage 10)"
if [ -f "$GR" ]; then
  perl -ni -e 'print unless /^\s*ndkVersion\s*=/' "$GR"
  perl -pi -e 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' "$GR"
  echo "   stripped ndkVersion, set minSdk=23 in $GR"
fi

echo "==> Forcing compileSdk 36 for all Android modules"
python3 tool/patch_android_compilesdk.py

echo "==> flutter pub get"
flutter pub get

echo "==> Generating launcher icons"
dart run flutter_launcher_icons

cat <<'EOF'

Done. Next (run each command on its own line, no trailing text):

  flutter devices
  flutter run
  (in the run session, press r = hot reload, R = restart, q = quit)

iOS on a real device (free Apple ID, 7-day, no paid account needed):
  open ios/Runner.xcworkspace
  set the Signing team once in Xcode, then:
  flutter run

Note: zsh does NOT treat '#' as a comment interactively, so never
paste a command with a trailing '# ...' note — it breaks the command.
EOF
