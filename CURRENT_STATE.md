# Current State

_Last updated: 2026-05-17_

## Status: v0.1 implemented; cloud CI added; awaiting first APK build

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
