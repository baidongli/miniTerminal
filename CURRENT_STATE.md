# Current State

_Last updated: 2026-05-17_

## Status: v0.2–v0.8 DEVICE-VERIFIED on Android (core features working)

User installed build #5 (commit 69ea883) on their Android phone and
confirmed core functionality works. Full roadmap (keys, security/jump
host, terminal theming, multi-session, SFTP, port forwarding, snippets,
app lock, settings, import/export) is implemented, CI-green for Android
+ iOS compile, and the core flows are verified on a real device.

Remaining work is polish and the known caveats below, not core
functionality.

### Local dev available (2026-05-17)
User has a full Mac toolchain (Flutter 3.44, Xcode 16, Android SDK,
devices). `tool/setup_local.sh` bootstraps an identical-to-CI local
env (`flutter run` hot reload; iOS on device via free Apple ID).
Claude still has no toolchain — but the feedback loop is now
local-fast: user runs locally, pastes exact errors, Claude fixes.
CI remains the release/artifact pipeline.

### Store distribution (2026-05-17)
- App id locked: `com.baidongli.miniterminal` (CI `--org com.baidongli`).
- Google Play: CI builds signed AAB when keystore Secrets are set
  (else skipped; APK sideload pipeline unaffected). See STORE_RELEASE.md.
- App Store: bundle id/version/icon ready; iOS job = release no-codesign
  until an Apple Developer account exists (hard Apple requirement).

### Polish pass (2026-05-17, CI-GREEN, build a5f9be0)
- APK now **20.7 MB** (was 157 MB debug) — release/arm64 split.
- **host-key TOFU**: wired into the dartssh2 handshake via
  `onVerifyHostKey`; first sighting trusted+stored, later mismatch
  rejected. Also passes `keepAliveInterval`.
- **APK slimming**: CI now builds `--release --split-per-abi` and
  publishes the arm64-v8a APK (~tens of MB vs 157 MB debug).
  Release is debug-signed by the Flutter template, so users must
  uninstall any prior debug build before installing (signature change;
  local data is lost).
- **Biometric**: workflow patches MainActivity →
  `FlutterFragmentActivity` and adds `USE_BIOMETRIC`.
- **Icon**: generated teal ">_" launcher icon via a stdlib PNG
  encoder (`tool/make_icon.py`), wired with `flutter_launcher_icons`.
- **i18n**: lightweight en/zh `AppLocalizations` + delegates; nav and
  Hosts screen localized. Remaining screens still English (incremental).

### Known runtime caveats (compile-safe, may need follow-up)
- **Biometric app lock**: Android needs `MainActivity` to extend
  `FlutterFragmentActivity` for `local_auth`. The default `flutter
  create` MainActivity is `FlutterActivity`; biometric prompt may fail
  at runtime until that's patched (CI build still succeeds).
- **Host-key verification**: store + known-hosts manager UI exist, but
  live TOFU verification is NOT wired into the dartssh2 handshake yet
  (API uncertainty without a compiler). Tracked in TASKS v0.3.
- Several dartssh2/SFTP/remote-forward APIs written to spec, unverified
  on a real build.

The full Dart codebase for v0.1 is written, committed, and pushed to
`claude/ssh-terminal-app-TGYBf`. It has **not** been compiled or run yet
(no Flutter toolchain in the cloud environment — the user builds locally).

## What works (code-complete, pending device verification)

- Host management: list, add, edit, delete (`hosts_screen.dart`,
  `host_edit_screen.dart`).
- Persistence: host metadata in `shared_preferences`, passwords in
  `flutter_secure_storage` (`host_store.dart`).
- SSH connect with password auth + interactive PTY shell terminal
  (`terminal_screen.dart`, `dartssh2` + `xterm`).
- Extra-key toolbar (ESC/TAB/CTRL-*/arrows/HOME/END).
- System light/dark theme.

## Not done / known gaps

- Never compiled or run — dependency versions and `dartssh2`/`xterm`
  API usage are written to spec but unverified on a real build.
- No native `ios/`/`android/` scaffolding committed (user runs
  `flutter create` — see README).
- No SSH key auth, no SFTP, no port forwarding, no host groups.
- No automated tests.
- No host-key verification / known_hosts handling (accepts any host key).

## Build path (decided)

User has **no computer / no Flutter / Android phone available**. Build
happens in **GitHub Actions** (`.github/workflows/android.yml`): every
push to the branch builds a debug APK and publishes it to the rolling
pre-release `android-latest`; user installs the APK directly on the
Android phone. A non-blocking macOS job also compile-checks iOS.

## Immediate next steps (for whoever picks this up)

1. Wait for the Actions run on the latest push; check the `android-latest`
   release has `miniterminal.apk`.
2. User installs the APK on the Android phone and reports any
   build/runtime errors (this is the first real compile — expect possible
   `dartssh2`/`xterm` API or dependency-version fixes).
3. Then proceed with the TASKS.md roadmap (key auth is the likely next
   feature).
