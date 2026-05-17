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
