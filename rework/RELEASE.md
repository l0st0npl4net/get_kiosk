# Release 0.1.0

First release of the Ratatui rewrite of the GET-KIOSK installer. Single statically linked
Linux binary plus an `assets/` and `app/` payload. No runtime installation, no interpreter,
no shared libraries.

| | |
|---|---|
| Version | `0.1.0` |
| Target | `x86_64-unknown-linux-musl` (static) |
| Built | 2026-11-17T10:28:04Z |
| Binary size | 1,649,456 bytes (stripped) |
| Archive size | 9,819,156 bytes |
| Hosts | Debian 11, 12, 13 (glibc version irrelevant) |

## Artifacts

Upload both files to the GitHub release page.

| File | Purpose |
|------|---------|
| `kiosk-installer-0.1.0-linux-x86_64.zip` | versioned archive, permanent record |
| `kiosk-installer-linux-x86_64.zip` | stable name, always points at the newest build |

`start.sh` always downloads the stable name:

- latest release — `https://github.com/<repo>/releases/latest/download/kiosk-installer-linux-x86_64.zip`
- pinned tag — `https://github.com/<repo>/releases/download/<tag>/kiosk-installer-linux-x86_64.zip`

Both zips have identical content; the versioned one exists so an older build stays
downloadable after the stable name moves on.

## Install

```bash
sudo ./start.sh
```

Pin a specific build:

```bash
KIOSK_VERSION=v0.1.0 sudo ./start.sh
```

`start.sh` is a shell script by design and is excluded from the repository. It does no
compilation and needs no Rust toolchain on the kiosk:

1. re-executes itself through `sudo` when not root;
2. installs the runtime packages the steps invoke (`sudo`, `ca-certificates`, `curl`, `wget`,
   `unzip`, `crudini`) if missing;
3. downloads the release zip and unpacks it to `/tmp/get_kiosk`;
4. locates the binary, `assets/` and `app/` in the archive;
5. exports `KIOSK_ROOT`, `KIOSK_ASSETS` and `KIOSK_LOG`, then executes the binary.

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `KIOSK_REPO` | `l0st0npl4net/get_kiosk` | repository the release is fetched from |
| `KIOSK_VERSION` | `latest` | `latest` or a release tag such as `v0.1.0` |
| `KIOSK_LOG` | `/tmp/kiosk_install.log` | install log destination |
| `KIOSK_WORK` | `/tmp/get_kiosk` | unpack directory for the release |
| `KIOSK_REPO_KEY_FPR` | set inside `start.sh` | OpenPGP fingerprint of the `getit-repo-2026.gpg` key |
| `KIOSK_ROOT` | set by `start.sh` | directory holding `app/` |
| `KIOSK_ASSETS` | set by `start.sh` | directory holding `assets/` |

`KIOSK_ROOT` and `KIOSK_ASSETS` are only needed when the binary is started by hand out of an
unpacked archive.

## Archive layout

```
kiosk-installer-0.1.0-linux-x86_64/
├── kiosk-installer      static ELF, mode 0755
├── VERSION              version, target, build timestamp
├── assets/              12 text payloads read at run time
└── app/
    ├── printer/         CUPS drivers, PPDs, raster_to_printer filters
    ├── terminals/       Sberbank, Inpas, Arcus payloads
    ├── fiscal/          ATOL and SHTRIH-M payloads
    └── sst/             SST-IIKO payloads
```

Vendor binaries and PPDs stay as files and are copied by the installer when the matching
component is selected. Nothing from `assets/` or `app/` is compiled into the binary, so a
payload can be edited in place without a rebuild.

## Components

All 13 entries of the original `dialog --checklist` are implemented, in the same order.

| # | Component | Result |
|---|-----------|--------|
| 1 | Proxy user | `proxyuser` account with passwordless sudo |
| 2 | OpenVPN | client plus remote profile |
| 3 | Hostname | hostname and `/etc/hosts` entry |
| 4 | GetIt repo | TLS-pinned apt repository |
| 5 | Get-Kiosk setup | SST-IIKO card reader software and config |
| 6 | Sleep off | DPMS and screen blanking disabled |
| 7 | Bank terminal | pinpad udev rule plus Sberbank / Inpas / Arcus integration |
| 8 | Fiscal device | ATOL or SHTRIH-M fiscal driver |
| 9 | Receipt printer | CUPS queue with the selected PPD, USB / VCOM / NETWORK |
| 10 | VNC install | `x11vnc` plus systemd units |
| 11 | VNC enable | switch to the VNC remote display |
| 12 | VNC disable | revert to the direct display |
| 13 | Zabbix agent | agent with kiosk checks |

Supported hardware lists live in `src/catalog.rs`: 8 pinpad models, 3 bank integrations,
11 printer models, 3 connection types, 2 fiscal vendors.

## Notes on behaviour

- Steps never abort the run on a non-zero child exit. The step is marked with a warning and
  the run continues, matching the original scripts, which never used `set -e`.
- No step reads from stdin. Every value is collected on the form screen before anything runs,
  so a step cannot hang waiting for input while the alternate screen is held.
- The GetIt repository is added only after the signing key is verified. `getit-repo-2026.gpg`
  is downloaded to a temporary file, its OpenPGP fingerprint is read with
  `gpg --show-keys --with-colons`, and it is compared with the expected value before
  `gpg --dearmor` installs the keyring. The expected fingerprint is not compiled in and not
  committed — `start.sh` exports it as `KIOSK_REPO_KEY_FPR`, and that script is excluded from
  the repository. A missing, malformed or mismatching fingerprint skips the write with an
  error line and no source list is created, so the installer never trusts an unverified key.
- Inputs interpolated into shell commands are validated: the kassa host accepts only
  `[A-Za-z0-9._-]`, the printer port must be numeric.
- Files written with `sudo tee` are applied atomically. The log records a one-line summary
  per file instead of the full payload.
- Empty optional values (VPN URL, ATOL version, SSH key) produce a warning and skip that
  action rather than failing the step.

## Build provenance

Built on Windows with `rust-lld`, no Linux host, WSL, Docker or zig involved:

```powershell
.\rework\build-release.ps1
```

Reproducible on Linux or in the container instead:

```bash
./rework/build-release.sh
docker build -f rework/Dockerfile.release -t kiosk-release .
docker run --rm -v "$PWD/rework/release:/src/rework/release" kiosk-release
```

The crate tree is pure Rust (`ratatui`, `crossterm`, `tokio`, `color-eyre`), so the musl
target needs only a linker; Rust's bundled `rust-lld` provides it. The build script refuses to
package a file that is not a Linux ELF, so a wrong target triple fails loudly instead of
shipping a Windows executable.

Release profile: `lto = true`, `codegen-units = 1`, `strip = true`.

## Upgrade and rollback

Re-running `start.sh` fetches the current stable archive and overwrites the unpack directory.
Steps are idempotent, so a re-run re-applies configuration rather than duplicating it. To roll
back, point `KIOSK_VERSION` at an older tag whose versioned archive is still on the release
page.

## Known limitations

- `x86_64` only. No arm64 archive in this release.
- The TUI needs a terminal. Started over a bare serial console without `TERM`, colors degrade
  to plain text but the layout still renders.
- `install.sh` and the `dialog` front end stay in the repository for reference; the binary does
  not call them.

## Verification performed

- Binary magic checked as `7f 45 4c 46`, ELF64, type 3 (static-pie) — a Linux executable, not
  a Windows one.
- Archive inspected: top-level directory with `kiosk-installer`, `VERSION`, `assets/` (12
  files), `app/{printer,terminals,fiscal,sst}` populated.
- `cargo fmt`, `cargo clippy --all-targets -- -D warnings` and `cargo build --release` clean.
- Not yet validated on physical kiosk hardware through `start.sh` end to end.
