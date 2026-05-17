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
