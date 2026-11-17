# get_kiosk — Ratatui rewrite

Interactive kiosk installer, rewritten from `dialog` shell scripts to a Rust TUI using
[Ratatui](https://ratatui.rs) 0.30. Behaviour and file layout of the original installers are
preserved; only the front end and orchestration changed.

## Layout

```
rework/
├── start.sh              # release entry point (kept out of git)
├── RELEASE.md            # notes for the current release (0.1.0)
├── build-release.sh      # builds the distributable archive into release/
├── Dockerfile.release    # Debian 13 / musl build container
├── Cargo.toml
├── assets/               # text payloads, shipped next to the binary
├── release/              # build output (git ignored)
└── src/
    ├── main.rs           # ratatui::run + KIOSK_ROOT / KIOSK_ASSETS resolution
    ├── app.rs            # Elm Architecture: Model / Message / update / view
    ├── ui.rs             # header, menu, form, review, run log, result popup
    ├── steps.rs          # step catalogue and per-step input fields
    ├── catalog.rs        # udev ids, printer models, repo pin
    ├── install.rs        # native implementation of all 13 installer steps
    ├── exec.rs           # subprocess runner with streamed output and logging
    ├── task.rs           # plan execution on a background task
    └── assets.rs         # locates assets/ and reads payloads at run time
```

Nothing is compiled into the binary. A release archive carries the executable, `assets/` and
the `app/` payload (`printer`, `terminals`, `fiscal`, `sst`), so driver packages, PPDs and
vendor binaries stay in the checkout and are copied by the installer at run time.

## Releases

Current release: **0.1.0** — see [RELEASE.md](RELEASE.md) for artifacts, install
instructions, archive layout, component list and known limitations.

## Running

```bash
sudo ./rework/start.sh
```

`start.sh` is a shell script by design (the original entry point was excluded from the
repository). It compiles nothing:

1. re-executes itself through `sudo` when not root;
2. installs the runtime dependencies the steps call (`wget`, `unzip`, `crudini`, ...);
3. downloads `kiosk-installer-linux-x86_64.zip` from the GitHub releases page;
4. unpacks it to `/tmp/get_kiosk` and locates the binary, `assets/` and `app/`;
5. executes the binary with `KIOSK_ROOT`, `KIOSK_ASSETS` and `KIOSK_LOG` exported.

Environment overrides:

| Variable | Default | Purpose |
|----------|---------|---------|
| `KIOSK_REPO` | `l0st0npl4net/get_kiosk` | repository the release is downloaded from |
| `KIOSK_VERSION` | `latest` | `latest` or a release tag such as `v0.1.0` |
| `KIOSK_LOG` | `/tmp/kiosk_install.log` | install log destination |
| `KIOSK_WORK` | `/tmp/get_kiosk` | unpack directory for the release |
| `KIOSK_REPO_KEY_FPR` | set inside `start.sh` | OpenPGP fingerprint of the `getit-repo-2026.gpg` key |

`KIOSK_ROOT` and `KIOSK_ASSETS` are set by `start.sh`; set them manually only when running
the binary directly out of an unpacked archive.

## Building a release

From Windows, no Linux machine, WSL, Docker or zig needed:

```powershell
.\rework\build-release.ps1
```

From Linux or the container:

```bash
./rework/build-release.sh
```

`build-release.ps1` cross-compiles on Windows because the crate tree has no C dependencies:
`ratatui`, `crossterm`, `tokio`, `color-eyre` and `textwrap` are pure Rust, so the musl target
needs only a linker. Rust's bundled `rust-lld` does that job (`RUSTFLAGS=-C linker=rust-lld`),
and the script refuses to package a file that is not a Linux ELF. First run needs:

```powershell
rustup target add x86_64-unknown-linux-musl
```

Neither script requires `cargo-zigbuild` or zig. Switch to zig only if a C dependency is ever
added later; until then `rust-lld` is the shorter path.

Both scripts write two archives into `rework/release/`:

- `kiosk-installer-<version>-linux-x86_64.zip` — versioned, for the release page record
- `kiosk-installer-linux-x86_64.zip` — stable name that `start.sh` always downloads

Both contain:

```
kiosk-installer      statically linked binary (x86_64-unknown-linux-musl)
assets/              text payloads read at run time
app/printer          CUPS drivers and filters
app/terminals        Sberbank, Inpas, Arcus payloads
app/fiscal           fiscal device payloads
app/sst              SST-IIKO payloads
VERSION              version, target and build timestamp
```

The musl target links statically, so one archive runs on Debian 11, 12 and 13 without
matching the host glibc. Build on a Debian 13 host, or in the supplied container:

```bash
docker build -f rework/Dockerfile.release -t kiosk-release .
docker run --rm -v "$PWD/rework/release:/src/rework/release" kiosk-release
```

Upload the resulting zip to the GitHub release page and `start.sh` picks it up:

```bash
KIOSK_VERSION=v0.1.0 sudo ./rework/start.sh
```

## Screens

1. **Menu** — component checklist, same 13 entries and order as the original
   `dialog --checklist`. `Space` toggles, `Enter` continues.
2. **Form** — only the inputs a selected component needs (URLs, hostname, models, ports).
3. **Review** — the ordered plan with every captured value, so nothing runs unseen.
4. **Run** — live log, per-step status badges, `↑↓`/`PgUp`/`PgDn` scrolling, `Ctrl-C` to stop.
5. **Result** — counts of clean and warning steps, elapsed time, log path.

A step with commands that exited non-zero is marked with warnings rather than aborting the
run, matching the original scripts, which never used `set -e`.

## Mapping from the shell installer

| Original | Rewrite |
|----------|---------|
| `install.sh` dialog checklist | `src/app.rs` menu + `src/steps.rs` |
| `app/proxyuser.sh` | `install::proxy_user` |
| `app/vpn.sh` | `install::vpn` |
| `app/hostname.sh` | `install::hostname` |
| `app/sst/repo.sh` | `install::sst_repo` (key digest enforced before writing the source) |
| `app/sst/setup.sh` | `install::sst_setup` |
| `app/sleep_off.sh` | `install::sleep_off` |
| `app/terminals/setup.sh` | `install::terminal` + `sber` / `inpas` / `arcus` |
| `app/fiscal/setup.sh` | `install::fiscal` (ATOL template written once) |
| `app/printer/setup.sh` | `install::printer` (USB / VCOM / NETWORK) |
| `app/vnc/*.sh` | `install::vnc_install`, `vnc_enable`, `vnc_disable` |
| `app/zabbix/zabbix.sh` | `install::zabbix` |

## Deliberate differences

- The generated `package.sh` is gone. Steps run in-process, in the order shown on the review
  screen.
- `dialog` interactive prompts are replaced by the form screen; every value is collected
  before anything runs, so no step can block on stdin.
- Inputs used inside shell commands are validated: the kassa host accepts only
  `[A-Za-z0-9._-]`, and the printer port must be numeric.
- Files written with `sudo tee` are applied atomically, and the log records a one-line
  summary instead of the whole payload.
- The repository signing key is verified before use: `getit-repo-2026.gpg` is downloaded, its
  OpenPGP fingerprint is read with `gpg --show-keys` and compared with `KIOSK_REPO_KEY_FPR`
  (a key fingerprint, not the TLS certificate) before `gpg --dearmor` writes the keyring.
  `start.sh` holds the expected fingerprint and exports it; that script stays out of the
  repository. Without a well-formed fingerprint the repo step refuses to run.
- Empty optional values (VPN URL, ATOL version, SSH key) produce a warning line and skip that
  action instead of failing.

## Build checks

```bash
cargo fmt --manifest-path rework/Cargo.toml
cargo clippy --manifest-path rework/Cargo.toml --all-targets -- -D warnings
cargo build --release --manifest-path rework/Cargo.toml
```

## Requirements

- Debian 11+ host, root or sudo
- Rust 1.88 or newer (installed by `start.sh` when absent)
- Network access for `apt` and vendor scripts
