"""Inject upload-key signing into the Flutter-generated Kotlin Gradle.

Run in CI after `flutter create`, only when a real keystore + key.properties
were provided. Idempotent and defensive: if expected anchors are missing it
leaves the file untouched (the build then falls back to Flutter's default
debug signing, so the APK pipeline never regresses).

Usage: python3 tool/patch_android_signing.py
"""
import sys

GRADLE = "android/app/build.gradle.kts"
MARKER = "// miniterminal-signing-injected"

IMPORTS = """import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
""" + MARKER + "\n\n"

SIGNING_BLOCK = """
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
"""

OLD_SIGN = 'signingConfig = signingConfigs.getByName("debug")'
NEW_SIGN = (
    'signingConfig = if (keystorePropertiesFile.exists()) '
    'signingConfigs.getByName("release") '
    'else signingConfigs.getByName("debug")'
)


def main() -> int:
    try:
        with open(GRADLE, "r", encoding="utf-8") as f:
            src = f.read()
    except FileNotFoundError:
        print(f"WARN: {GRADLE} not found; skipping signing patch.")
        return 0

    if MARKER in src:
        print("Signing patch already applied; skipping.")
        return 0

    if "plugins {" not in src or "android {" not in src:
        print("WARN: unexpected build.gradle.kts shape; leaving default "
              "(debug) signing. APK pipeline unaffected.")
        return 0

    src = IMPORTS + src

    idx = src.index("android {") + len("android {")
    src = src[:idx] + "\n" + SIGNING_BLOCK + src[idx:]

    if OLD_SIGN in src:
        src = src.replace(OLD_SIGN, NEW_SIGN)
    else:
        print("WARN: default debug signingConfig line not found; release "
              "buildType will use Flutter default. Continuing.")

    with open(GRADLE, "w", encoding="utf-8") as f:
        f.write(src)
    print("Signing patch applied to", GRADLE)
    return 0


if __name__ == "__main__":
    sys.exit(main())
