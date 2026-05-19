# Work Log

Append-only. Newest entry on top. One entry per meaningful stage.
Template:

```
## YYYY-MM-DD — <short title>
**Done:** what changed
**Why:** rationale / decisions
**Files:** key files touched
**Next:** the immediate follow-up
```

---

## 2026-05-17 — Store-ready: real bundle id + Play AAB + iOS scaffolding

**Done:** Locked app id `com.baidongli.miniterminal` (CI uses
`flutter create --org com.baidongli`). CI now also builds a **signed
AAB** for Google Play when keystore GitHub Secrets are present
(`tool/patch_android_signing.py` injects upload-key signing into the
Kotlin Gradle; defensive — no secrets ⇒ skipped, APK pipeline
unchanged). Build number from CI run number for monotonic versionCode.
iOS job builds release (no codesign) pending an Apple Developer
account; signing/upload steps documented for later. Added
STORE_RELEASE.md.
**Why:** User wants App Store + Google Play distribution; has Play
Console, no Apple account yet.
**Files:** .github/workflows/android.yml, tool/patch_android_signing.py,
STORE_RELEASE.md, CLAUDE.md
**Next:** User creates upload keystore + adds 4 GitHub Secrets → CI
emits Play-ready AAB; later, Apple account → wire iOS signing/upload.

## 2026-05-17 — Fix compileSdk patch ordering (afterEvaluate)

**Done:** Appended compileSdk override failed:
`Cannot run Project.afterEvaluate when the project is already
evaluated` — Flutter's `subprojects { evaluationDependsOn(":app") }`
pre-evaluates subprojects, so an afterEvaluate appended after it is
invalid. New `tool/patch_android_compilesdk.py` INSERTS the block
BEFORE the first `subprojects {` (valid registration, still overrides
plugin defaults). setup_local.sh + CI now call it instead of appending.
**Files:** tool/patch_android_compilesdk.py, tool/setup_local.sh,
.github/workflows/android.yml, STACK_NOTES_FLUTTER.md
**Next:** User pulls, re-runs setup_local.sh + flutter run.

## 2026-05-17 — Force compileSdk 36 (plugin AAR metadata conflict)

**Done:** Build got past NDK; new error: `file_picker` →
`flutter_plugin_android_lifecycle` requires compileSdk 36 but plugin
modules compiled against android-34. setup_local.sh + CI now append a
`subprojects { afterEvaluate { ... compileSdkVersion(36) } }` override
to the project-level `android/build.gradle.kts`. (Transient network
blips during the run self-recovered via Gradle retry.)
**Files:** tool/setup_local.sh, .github/workflows/android.yml,
STACK_NOTES_FLUTTER.md
**Next:** User pulls, re-runs setup_local.sh + flutter run.

## 2026-05-17 — Strip forced NDK (no native code; unblock local build)

**Done:** Local `flutter run` kept failing: Flutter 3.44 template
forces `ndkVersion = flutter.ndkVersion`, Gradle tried to download NDK,
flaky network produced a corrupt NDK (`Archive is not a ZIP` /
`CXX1101 ... no source.properties`), infinite retry. App has zero
native code → NDK unneeded. setup_local.sh + CI now delete the
`ndkVersion` line after `flutter create`. Documented in
STACK_NOTES_FLUTTER.
**Files:** tool/setup_local.sh, .github/workflows/android.yml,
STACK_NOTES_FLUTTER.md
**Next:** User deletes the corrupt NDK dir, pulls, re-runs
setup_local.sh + flutter run.

## 2026-05-17 — Local dev bootstrap (user has full Mac toolchain)

**Done:** User revealed a complete local environment (Flutter 3.44,
Xcode 16, Android SDK, 2 devices). Added `tool/setup_local.sh` that
reproduces CI's steps exactly (flutter create --org com.baidongli,
MainActivity→FragmentActivity, INTERNET/USE_BIOMETRIC, pub get, icons)
so local and CI builds don't drift. README gained a "Local development"
section. Feedback loop is now local-fast (no push→CI→screenshot);
Claude still can't compile cloud-side so CI stays the release pipeline.
iOS local device testing now possible via free Apple ID (paid account
only needed for App Store submission).
**Files:** tool/setup_local.sh, README.md, CURRENT_STATE.md
**Next:** User runs setup_local.sh + flutter run; iterate locally.

## 2026-05-17 — Split playbook: generic vs Flutter-specific

**Done:** Rewrote `DEVELOPMENT_PLAYBOOK.md` to be fully
stack-agnostic (added an "applicability assumptions" table; section 7
now generic principles; added a reuse checklist). Extracted all
Flutter/Android/iOS specifics into new `STACK_NOTES_FLUTTER.md`
(scaffolding, debug/release, size, store, native plugin config, Dart
API gotchas, mobile UX, CI shape). Linked both from CLAUDE.md.
**Why:** User wants the playbook reusable for non-Flutter apps too.
**Files:** DEVELOPMENT_PLAYBOOK.md, STACK_NOTES_FLUTTER.md, CLAUDE.md
**Next:** Reuse the generic playbook on future apps; keep STACK_NOTES
per stack.

## 2026-05-17 — Add reusable DEVELOPMENT_PLAYBOOK.md

**Done:** Distilled the working practices from this project into an
app-agnostic playbook (startup decisions, doc system, CI-as-compiler,
small commits, API verification, debug/release pitfalls, branch
strategy, honesty rules). Linked from CLAUDE.md.
**Why:** User wants a reusable spec for future apps.
**Files:** DEVELOPMENT_PLAYBOOK.md, CLAUDE.md
**Next:** Apply it on this and future projects.

## 2026-05-17 — Merge feature branch into main

**Done:** Per user request, merged `claude/ssh-terminal-app-TGYBf`
(14 commits, fast-forward, no conflicts) into `main`; all future work
on `main`. CI trigger switched from the feature branch to `main`;
CLAUDE.md updated.
**Files:** .github/workflows/android.yml, CLAUDE.md
**Next:** Develop directly on `main` going forward.

## 2026-05-17 — Compact-prompt toggle

**Done:** Root cause of "no room to type" was the server's long PS1
(Alibaba ECS instance-id hostname), not the app. Added per-host
**Compact prompt** switch (host_edit) → on connect, session_manager
injects `export PS1='[\u \W]\$ '` (+ clears PROMPT_COMMAND). New
`compactPrompt` field on SshHost (json/copyWith).
**Files:** models/ssh_host.dart, ssh/session_manager.dart,
screens/host_edit_screen.dart
**Next:** User rebuilds, enables it on the host, verifies short prompt.

## 2026-05-17 — Connection works; reclaim terminal width

**Done:** INTERNET fix confirmed — SSH connects and runs commands on
device. User reported wasted left/edge space; set `TerminalView.padding`
to `EdgeInsets.zero` so columns use the full width.
**Files:** lib/screens/terminal_screen.dart
**Next:** User rebuilds, checks the terminal now uses full width.

## 2026-05-17 — Fix release regression: missing INTERNET permission

**Done:** Device test of the slim release APK failed all connections
with `OS Error: Operation not permitted, errno = 1`. Cause: Flutter
only injects `android.permission.INTERNET` into the debug/profile
manifests; the release main manifest lacks it. Workflow now patches
INTERNET (and biometric) into the main AndroidManifest and prints it.
**Why:** Regression from switching debug→release for APK slimming.
**Files:** .github/workflows/android.yml
**Next:** Rebuild; user reinstalls and retries the connection.

## 2026-05-17 — Polish pass GREEN; APK 157 MB → 20.7 MB

**Done:** Build for commit a5f9be0 passed; release arm64 APK is
20.7 MB (was 157 MB), published to `android-latest`. host-key TOFU,
biometric patch, icon, and i18n shipped.
**Next:** User uninstalls old build, installs the slim APK, verifies
icon / zh locale / biometric unlock / host-key trust on device.

## 2026-05-17 — Polish pass: host-key, APK slim, biometric, icon, i18n

**Done:** All four user-selected polish items in one pass:
- host-key TOFU wired via `onVerifyHostKey` (verified the dartssh2 API
  by fetching pub.dev docs first); + `keepAliveInterval`. New
  `knownHosts` dep threaded into SshConnection + 3 call sites.
- CI builds `--release --split-per-abi`, publishes arm64-v8a APK
  (Flutter template debug-signs release, so installable; users must
  uninstall old debug build first).
- Workflow patches MainActivity → FlutterFragmentActivity + adds
  USE_BIOMETRIC for local_auth.
- Generated launcher icon with a pure-stdlib PNG encoder
  (tool/make_icon.py, no PIL available) + flutter_launcher_icons.
- Lightweight en/zh AppLocalizations + Flutter global delegates; nav +
  Hosts localized; other screens English pending incremental work.
**Why:** User selected all four polish items.
**Files:** ssh_connection.dart, main.dart, sftp_screen.dart,
port_forward_screen.dart, home_screen.dart, hosts_screen.dart,
l10n/app_localizations.dart, pubspec.yaml, .github/workflows/android.yml,
tool/make_icon.py, assets/icon/icon.png
**Next:** CI green check; verify icon shows, zh locale, biometric on
device, smaller APK installs after uninstalling old build.

## 2026-05-17 — Android device-verified (core features working)

**Done:** User installed build #5 on their Android phone and confirmed
core functionality works end to end. The full v0.1–v0.8 roadmap is now
device-verified for core flows.
**Why:** Milestone — a working free Termius alternative.
**Next:** Polish only. Open items: APK size slimming, biometric
MainActivity patch, host-key TOFU wiring, deeper testing of
SFTP/port-forwarding, optional i18n, iOS distribution path. Await user's
priority.

## 2026-05-17 — CI GREEN for the full roadmap

**Done:** Build #5 (commit 69ea883) passed both jobs — Android APK build
and iOS compile check. The entire v0.1–v0.8 codebase now compiles for
Android and iOS. APK auto-published to the `android-latest` release
(~157 MB; debug build with all ABIs — slimming is tracked in
engineering debt).
**Why:** Two compile-fix rounds (const ctor; name clash + BytesBuilder)
were enough; the rest of the large rebuild compiled clean.
**Next:** User installs the new APK and functionally tests each feature
area (keys, jump host, themes, multi-session, SFTP, forwarding,
snippets, app lock). Watch the known caveats: biometric MainActivity,
host-key TOFU not wired, unverified-at-runtime dartssh2 SFTP/forward.

## 2026-05-17 — Fix #2: name clash + BytesBuilder API

**Done:** CI compile of the big rebuild surfaced two errors: (1) my
`TerminalThemes` clashed with xterm's own `TerminalThemes` → renamed to
`AppTerminalThemes`; (2) `dart:typed_data` `BytesBuilder` has no
`addAll` → switched to `add(List<int>)` / `addByte(int)` in key_gen.
**Files:** lib/ssh/terminal_themes.dart, lib/screens/terminal_screen.dart,
lib/ssh/key_gen.dart
**Next:** Re-run CI; keep clearing compile errors until green.

## 2026-05-17 — v0.1 verified; v0.2–v0.8 implemented in one pass

**Done:** User confirmed v0.1 works on their Android phone. Then did a
full architecture rebuild and implemented the rest of the roadmap in one
go (committed for CI to compile-check):
- Models: extended SshHost (auth/key/group/jump/startup/tags), SshKey,
  HostGroup, Snippet, AppSettings.
- Stores: key/group/snippet/settings/known-hosts + JsonPrefs helper.
- SSH layer: SshConnection (password+key auth, jump host), key_gen
  (ed25519 → OpenSSH), SessionManager (multi-session), port_forwarding
  (local+remote), terminal_themes (4 themes).
- State: AppRepository + provider; AppLock (local_auth).
- Screens: home (bottom nav + session badge), hosts (search/groups),
  host_edit (auth/key/group/jump/startup/tags), terminal
  (theme/snippets/SFTP/forward menu), keys (gen/import/paste),
  groups, snippets, sessions, sftp, port_forward, settings
  (theme/font/scrollback/app-lock/import-export), known_hosts, lock.
- Deps added: provider, file_picker, path_provider, local_auth,
  cryptography.
**Why:** User asked to complete the whole roadmap without stopping.
Done as one coherent architecture change; per-version commits were not
possible because the rewrite is cross-cutting (shared models/state).
**Caveats:** see CURRENT_STATE — biometric MainActivity, host-key TOFU
not wired into handshake, unverified dartssh2/SFTP APIs.
**Files:** ~30 files under lib/, pubspec.yaml
**Next:** Get CI green; fix any API mismatches from the first compile of
the new code.

## 2026-05-17 — Full feature development list

**Done:** Expanded TASKS.md from a skeleton into a complete, prioritized
feature roadmap (v0.1–v0.8 + backlog + engineering debt), each block
with an acceptance criterion. Covers key auth, host-key verification,
jump host, terminal theming, multi-session, SFTP, port forwarding,
snippets, app lock, i18n, etc.
**Why:** User asked for a proper feature list to drive development while
the first build runs.
**Files:** TASKS.md
**Next:** Confirm v0.1 build is green, then start v0.2 (SSH key auth).

## 2026-05-17 — Fix first build failure (const constructor)

**Done:** First CI build failed at `assembleDebug` with a Dart compile
error: `throw const SSHAuthAbortError(...)` — `SSHAuthAbortError` is not
a const constructor. Removed `const`.
**Why:** Code had never been compiled; this is exactly the kind of API
detail the first real build surfaces. Toolchain/CI itself works
(`flutter create` + `pub get` passed).
**Files:** lib/screens/terminal_screen.dart
**Next:** Re-triggered build on push; verify it goes green and the APK
appears in the `android-latest` release.

## 2026-05-17 — Cloud build via GitHub Actions (no computer needed)

**Done:** Added `.github/workflows/android.yml`: on push to the branch
it generates platform scaffolding, builds a debug APK, uploads it as an
artifact, and publishes it to a rolling pre-release tagged
`android-latest`. Added a non-blocking macOS job that compile-checks iOS
(`flutter build ios --no-codesign`). Documented the phone-only install
path in README.
**Why:** User has no computer/Flutter, only an Android phone. iOS device
install has no free computer-less path (signing constraint); Android APK
sideload is fully free. Debug APK is self-signed so it installs without
any keystore setup.
**Files:** .github/workflows/android.yml, README.md, CURRENT_STATE.md,
TASKS.md
**Next:** Confirm the first Actions run is green and the
`android-latest` release has `miniterminal.apk`; user installs and
reports runtime issues.

## 2026-05-17 — Project docs added

**Done:** Created project documentation: `CLAUDE.md` (session entry
point / working agreement), `CURRENT_STATE.md` (progress snapshot),
`TASKS.md` (versioned roadmap), `WORKLOG.md` (this file).
**Why:** User needs to resume context in fresh sessions and track
staged progress over time.
**Files:** CLAUDE.md, CURRENT_STATE.md, TASKS.md, WORKLOG.md
**Next:** User builds v0.1 locally and reports compile/runtime results.

## 2026-05-17 — v0.1 implemented (host mgmt + SSH connect)

**Done:** Built the full Flutter app for v0.1 — host CRUD, secure
password storage, password-auth SSH with an interactive xterm PTY
terminal, and an extra-key toolbar. Scaffolded pubspec, lints,
gitignore, README.
**Why:** Agreed scope with user: Flutter stack, first version covers
host management + SSH connection only. Native `ios/`/`android/` folders
intentionally not committed (generated via `flutter create` locally).
Host keys currently accepted without verification — flagged as a gap
for v0.3.
**Files:** pubspec.yaml, analysis_options.yaml, .gitignore, README.md,
lib/main.dart, lib/models/ssh_host.dart, lib/services/host_store.dart,
lib/screens/{hosts,host_edit,terminal}_screen.dart
**Next:** User builds locally (no Flutter toolchain in cloud env) and
reports any API/version mismatches to fix.
