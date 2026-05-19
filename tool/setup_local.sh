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

GR=android/app/build.gradle.kts
echo "==> Removing forced NDK (app has no native code; avoids NDK download)"
if [ -f "$GR" ]; then
  perl -ni -e 'print unless /^\s*ndkVersion\s*=/' "$GR"
  echo "   stripped ndkVersion from $GR"
fi

PROJ=android/build.gradle.kts
echo "==> Forcing compileSdk 36 for all Android modules"
if [ -f "$PROJ" ] && ! grep -q 'miniterminal-compilesdk' "$PROJ"; then
  cat >> "$PROJ" <<'KTS'

// miniterminal-compilesdk: some plugins (file_picker ->
// flutter_plugin_android_lifecycle) require compileSdk 36. Force it on
// every Android subproject regardless of each plugin's own default.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileSdkVersion"(36)
        }
    }
}
KTS
  echo "   appended compileSdk=36 override to $PROJ"
fi

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
