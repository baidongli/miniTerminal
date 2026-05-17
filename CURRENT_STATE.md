# Current State

_Last updated: 2026-05-17_

## Status: v0.1 implemented, not yet built/tested on a device

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

## Immediate next steps (for whoever picks this up)

1. User: build locally (`flutter create ... .`, `flutter pub get`,
   `flutter run`) and report any compile/runtime errors.
2. Fix any API mismatches surfaced by the first real build.
3. Then proceed with the TASKS.md roadmap (key auth is the likely next
   feature).
