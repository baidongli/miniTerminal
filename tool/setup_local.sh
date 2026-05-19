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

echo "==> Generating android/ ios/ scaffolding (org $ORG)"
flutter create --org "$ORG" --project-name miniterminal \
  --platforms=android,ios .

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

echo "==> flutter pub get"
flutter pub get

echo "==> Generating launcher icons"
dart run flutter_launcher_icons

cat <<'EOF'

Done. Next:
  flutter devices            # list connected devices
  flutter run                # run on a device/simulator (hot reload: r)

iOS on a real device (free Apple ID, 7-day, no paid account needed):
  open ios/Runner.xcworkspace   # set Signing team once, then:
  flutter run -d <ios-device-id>
EOF
