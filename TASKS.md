# Tasks / Roadmap

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done ·
`[!]` blocked/needs user

## v0.1 — Host management + SSH connection (MVP)

- [x] Project scaffold (pubspec, lints, gitignore, README)
- [x] `SshHost` model
- [x] `HostStore` persistence (prefs + secure storage)
- [x] Host list screen (add/edit/delete/connect)
- [x] Host edit form with validation
- [x] SSH connect + interactive terminal (dartssh2 + xterm)
- [x] Extra-key toolbar
- [x] Project docs (CLAUDE/CURRENT_STATE/TASKS/WORKLOG)
- [x] GitHub Actions: cloud APK build + rolling release (no computer needed)
- [~] First real build green on CI (triggered, awaiting result)
- [ ] User installs APK on Android phone, reports issues
- [ ] Fix issues found in first real build

## v0.2 — SSH key management

- [ ] Generate ed25519/RSA keypair in-app
- [ ] Import existing private key (paste / file)
- [ ] Store private keys in secure storage
- [ ] Key-based auth in connection flow
- [ ] Per-host auth selector (password vs key)

## v0.3 — Terminal experience

- [ ] Color themes (presets)
- [ ] Adjustable font size
- [ ] Copy / paste polish, text selection
- [ ] Reconnect / keep-alive handling
- [ ] Host-key verification (known_hosts, trust-on-first-use)

## v0.4 — SFTP

- [ ] Remote directory browser
- [ ] Upload / download files
- [ ] Basic file ops (rename/delete/mkdir)

## Backlog / later

- [ ] Port forwarding (local/remote)
- [ ] Snippets / command shortcuts
- [ ] Host groups & search
- [ ] Optional iCloud/cloud sync of hosts
- [ ] Biometric lock for the app
