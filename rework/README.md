# get_kiosk — Ratatui rewrite

Interactive kiosk installer, rewritten from `dialog` shell scripts to a Rust TUI using
[Ratatui](https://ratatui.rs) 0.30. Behaviour and file layout of the original installers are
preserved; only the front end and orchestration changed.

## Layout

```
rework/
├── start.sh              # entry point (kept out of git, like the original start.sh)
├── Cargo.toml
├── assets/               # text payloads embedded into the binary
└── src/
    ├── main.rs           # ratatui::run + tokio runtime + KIOSK_ROOT resolution
    ├── app.rs            # Elm Architecture: Model / Message / update / view
    ├── ui.rs             # header, menu, form, review, run log, result popup
    ├── steps.rs          # step catalogue and per-step input fields
    ├── catalog.rs        # udev ids, printer models, repo pin
    ├── install.rs        # native implementation of all 13 installer steps
    ├── exec.rs           # subprocess runner with streamed output and logging
    ├── task.rs           # plan execution on a background task
    └── assets.rs         # include_str! of assets/
```

Vendor payloads stay where they are: `app/printer/driver/*`, `app/terminals/*/`,
`app/fiscal/*`, `app/sst/*`. The Rust binary copies them from the checkout at run time, so
drivers do not have to be rebuilt into the executable.

## Running

```bash
sudo ./rework/start.sh
```

`start.sh` is a shell script by design (the original entry point was excluded from the
repository). It:

1. re-executes itself through `sudo` when not root;
2. installs the runtime dependencies the steps call (`wget`, `unzip`, `crudini`, ...);
3. downloads `https://github.com/<repo>/archive/refs/heads/<branch>.zip` and unpacks it when
   no `app/` directory sits next to the script, so a standalone copy still works;
4. installs `build-essential`, `pkg-config` and the Rust toolchain when missing;
5. builds `target/release/kiosk-installer` and executes it.

Environment overrides:

| Variable | Default | Purpose |
|----------|---------|---------|
| `KIOSK_ROOT` | detected checkout root | where `app/` lives |
| `KIOSK_LOG` | `/tmp/kiosk_install.log` | install log destination |
| `KIOSK_BRANCH` | `main` | branch used for the zip bootstrap |
| `KIOSK_REPO` | `l0st0npl4net/get_kiosk` | repository used for the zip bootstrap |

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
| `app/sst/repo.sh` | `install::sst_repo` (TLS pin enforced before writing the source) |
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
