# Feature Development List / Roadmap

A free Termius alternative. This is the master feature list, ordered by
version and priority. Each item has a short acceptance criterion so a
future session knows when it's "done".

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done ·
`[!]` blocked/needs user

---

## v0.1 — Host management + SSH connection (MVP) — IN PROGRESS

- [x] Project scaffold (pubspec, lints, gitignore, README)
- [x] `SshHost` model
- [x] `HostStore` persistence (prefs + secure storage)
- [x] Host list screen (add/edit/delete/connect)
- [x] Host edit form with validation
- [x] SSH connect + interactive terminal (dartssh2 + xterm)
- [x] Extra-key toolbar (ESC/TAB/CTRL/arrows)
- [x] Project docs (CLAUDE/CURRENT_STATE/TASKS/WORKLOG)
- [x] GitHub Actions: cloud APK build + rolling release
- [~] First real build green on CI
- [ ] User installs APK, smoke-tests a real SSH login
- [ ] Fix issues found in first real run

**Done when:** user can add a host, connect with password, and run
commands in the terminal on a real device.

---

## v0.2 — SSH key authentication

- [ ] Import existing private key (paste text or pick file)
- [ ] Generate ed25519 keypair in-app, show/copy public key
- [ ] Optional passphrase on private keys
- [ ] Store private keys in secure storage
- [ ] Per-host auth selector: password / key / agent
- [ ] Show public key for easy `authorized_keys` setup

**Done when:** a host can connect using an imported or generated key,
no password.

---

## v0.3 — Connection robustness & security

- [ ] Host-key verification: trust-on-first-use, store fingerprint,
      warn on change
- [ ] Known-hosts manager screen (view/forget trusted keys)
- [ ] Keep-alive (ServerAliveInterval) + auto-reconnect on drop
- [ ] Connection timeout & retry settings
- [ ] Jump host / ProxyJump (connect through a bastion)
- [ ] Quick Connect: one-off `user@host` without saving

**Done when:** dropped Wi-Fi reconnects cleanly and a changed host key
is flagged, connections can route through a bastion.

---

## v0.4 — Terminal experience

- [ ] Color theme presets (Dark, Solarized, Nord, etc.)
- [ ] Adjustable font family & size
- [ ] Adjustable scrollback buffer size
- [ ] Text selection + copy/paste polish
- [ ] Customizable extra-key bar (user picks keys)
- [ ] Landscape / tablet layout
- [ ] Per-session paste, "send line", clear

**Done when:** terminal look & input feel comparable to Termius free.

---

## v0.5 — Multiple sessions & organization

- [ ] Multiple concurrent sessions with a tab/switcher
- [ ] Host groups / folders
- [ ] Tags + search/filter on the host list
- [ ] Reusable Identities (credential separate from host)
- [ ] Reorder / favorite hosts

**Done when:** several servers stay connected at once and the host
list scales to dozens of entries.

---

## v0.6 — SFTP file transfer

- [ ] Remote directory browser
- [ ] Download file to device
- [ ] Upload file from device
- [ ] File ops: rename, delete, mkdir, chmod
- [ ] Transfer progress + cancel
- [ ] Open/preview small text files

**Done when:** files move both ways with visible progress.

---

## v0.7 — Power features

- [ ] Port forwarding: local, remote, dynamic (SOCKS)
- [ ] Snippets / saved commands, run into a session
- [ ] Startup command per host
- [ ] SSH agent forwarding
- [ ] Session logging to a file
- [ ] Import hosts from `~/.ssh/config` / JSON; export hosts

**Done when:** common Termius "pro" workflows are covered.

---

## v0.8 — App polish & security

- [ ] Biometric / passcode lock for the app
- [ ] Settings screen (defaults, theme, behavior)
- [ ] Localization: English + 中文
- [ ] Accessibility pass
- [ ] App icon + splash + store-ready metadata
- [ ] Encrypted local backup / restore of all hosts & keys

**Done when:** feels like a finished product, safe to keep real creds.

---

## Backlog / maybe-later

- [ ] Mosh support (UDP, roaming)
- [ ] Telnet / serial
- [ ] Optional end-to-end-encrypted cross-device sync
- [ ] iOS build path once a Mac / dev account is available
- [ ] Widgets / shortcuts (quick-connect from home screen)
- [ ] Themed terminal sharing / export config

---

## Cross-cutting / engineering debt

- [ ] State management cleanup as screens grow (consider a store/notifier)
- [ ] Unit + widget tests (HostStore, model, connection state machine)
- [ ] Error UX: consistent failure surfaces, not raw exception strings
- [ ] CI: cache Gradle, add `flutter analyze` + tests as gates
- [ ] Android release signing (proper keystore) for non-debug builds
