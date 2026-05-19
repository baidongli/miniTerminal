"""Force compileSdk 36 on all Android subprojects.

Some Flutter plugins (file_picker) compile against android-34 while a
transitive dep (flutter_plugin_android_lifecycle) requires 36. We
override every Android module's compileSdk via afterEvaluate.

Crucially this block must be INSERTED BEFORE Flutter's
`subprojects { project.evaluationDependsOn(":app") }` in the
project-level android/build.gradle.kts — that line force-evaluates
subprojects, and registering afterEvaluate after evaluation throws
"Cannot run Project.afterEvaluate when the project is already
evaluated". Registering it earlier is valid and still overrides each
plugin's own compileSdk (runs after the plugin's own build script).

Run in CI / setup_local.sh after `flutter create`. Idempotent;
defensive (no anchor -> leave file unchanged).

Usage: python3 tool/patch_android_compilesdk.py
"""
import sys

F = "android/build.gradle.kts"
MARK = "// miniterminal-compilesdk"
BLOCK = MARK + """: force compileSdk 36 on every Android module.
// Inserted before Flutter's evaluationDependsOn(":app") so the
// afterEvaluate registration is valid and overrides plugin defaults.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileSdkVersion"(36)
        }
    }
}

"""


def main() -> int:
    try:
        with open(F, "r", encoding="utf-8") as fh:
            src = fh.read()
    except FileNotFoundError:
        print(f"WARN: {F} not found; skipping compileSdk patch.")
        return 0

    if MARK in src:
        print("compileSdk patch already applied; skipping.")
        return 0

    idx = src.find("subprojects {")
    if idx == -1:
        print("WARN: no 'subprojects {' anchor in build.gradle.kts; "
              "leaving unchanged.")
        return 0

    src = src[:idx] + BLOCK + src[idx:]
    with open(F, "w", encoding="utf-8") as fh:
        fh.write(src)
    print("compileSdk=36 override inserted before first subprojects block.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
