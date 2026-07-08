# get_kiosk

Automated kiosk system installer and configuration toolkit for Debian-based Linux POS terminals. Provides modular setup scripts for financial hardware, payment terminals, printers, and system-level configuration.

## Overview

`get_kiosk` simplifies the deployment of Russian POS (point-of-sale) kiosk systems by automating the installation and configuration of:

- Financial receipt printers (Fiscal devices)
- Payment terminals (Sberbank, Inpas, Arcus integrations)
- Card readers (SST-IIKO)
- Printer drivers (CUPS)
- Remote desktop (X11VNC)
- System monitoring (Zabbix agent)
- Network and security (OpenVPN, proxy user, hostname)

## Quick Start

### One-Command Installation

```bash
curl -sSL https://github.com/l0st0npl4net/get_kiosk/raw/main/install.sh | sh
```

This bootstraps the repository and launches the interactive installer.

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/l0st0npl4net/get_kiosk.git
cd get_kiosk

# Run the interactive installer
sudo ./start.sh
```

The installer presents a `dialog`-based checklist allowing you to select which components to install. Selected scripts are combined into a `package.sh` and executed sequentially.

## Prerequisites

- Debian 11 (Bullseye) or compatible
- Root/sudo access
- `dialog`, `wget`, `unzip` installed
- Internet connection (for package downloads and VPN config retrieval)

<details>
<summary><strong>Bootstrap dependencies</strong></summary>

The `install.sh` script handles these automatically:

```bash
apt-get -y install sudo wget dialog nano crudini \
  x11-xserver-utils libfptr10=10.10.7.0
```

</details>

## Components

### System Configuration

| # | Component | Description |
|---|-----------|-------------|
| 0 | Set proxyuser | Creates `proxyuser` account with passwordless sudo and SSH key authentication |
| 1 | Setup VPN | Installs and configures OpenVPN with a remote `.ovpn` configuration |
| 2 | Change Hostname | Prompts for and applies a new system hostname |
| 4 | Sleep off | Disables screen blanking, DPMS, and screensaver via systemd services |

### Hardware Integration

| # | Component | Description |
|---|-----------|-------------|
| 3 | Get-Kiosk setup | Installs and configures SST-IIKO card reader driver and settings |
| 5 | Terminal setup | Integrates bank payment terminals (Sberbank, Inpas, Arcus) with supported models |
| 6 | Fiscal setup | Configures fiscal receipt printers (ATOL, SHTRIH-M) |
| 7 | Printer setup | Installs CUPS, selects printer model, and configures the connection (USB/VCOM/Network) |

### Remote Access & Monitoring

| # | Component | Description |
|---|-----------|-------------|
| 8 | VNC: install | Installs X11VNC and configures the systemd service for remote desktop access |
| 9 | VNC: enable | Switches to VNC mode (enables X11VNC + Xorg, disables direct display) |
| 10 | VNC: disable | Reverts to direct display mode (disables VNC, enables `sst-iiko` directly) |
| 11 | Zabbix | Installs the Zabbix agent with custom UserParameters for kiosk health monitoring |

## Directory Structure

```
get_kiosk/
├── install.sh              # Bootstrap script (downloads + launches installer)
├── start.sh                # Interactive dialog-based installer
├── app/
│   ├── proxyuser.sh        # Proxy user account setup
│   ├── vpn.sh              # OpenVPN configuration
│   ├── hostname.sh         # Hostname changer
│   ├── sleep_off.sh        # Screen saver / DPMS disable
│   ├── sst/
│   │   ├── setup.sh        # SST-IIKO card reader installer
│   │   └── check.sh        # SST-IIKO version check / update
│   ├── terminals/
│   │   ├── setup.sh        # Payment terminal integration orchestrator
│   │   ├── terminal.env    # Terminal model variables
│   │   ├── arcus/          # Arcus terminal driver
│   │   ├── inpas/          # Inpas terminal driver
│   │   └── sber/           # Sberbank terminal driver
│   ├── fiscal/
│   │   ├── setup.sh        # Fiscal printer orchestrator
│   │   ├── atol.sh         # ATOL fiscal device setup
│   │   ├── shtrih.sh       # SHTRIH-M fiscal device setup
│   │   └── fiscal.env      # Fiscal device variables
│   ├── printer/
│   │   ├── setup.sh        # CUPS printer installation and configuration
│   │   ├── vcom.env        # VCOM connection variables
│   │   └── driver/         # Printer-specific CUPS drivers
│   ├── vnc/
│   │   ├── setup.sh        # X11VNC installation and service config
│   │   ├── enable.sh       # Enable VNC remote desktop mode
│   │   └── disable.sh      # Disable VNC, revert to direct display
│   └── zabbix/
│       ├── zabbix.sh       # Zabbix agent installation
│       └── zabbix_agentd.conf  # Agent configuration template
```

## Usage Examples

### Install a specific component

```bash
# Install the fiscal printer (ATOL)
sudo bash app/fiscal/setup.sh

# Install and enable VNC
sudo bash app/vnc/setup.sh
sudo bash app/vnc/enable.sh

# Install Zabbix agent
sudo bash app/zabbix/zabbix.sh
```

### Check SST-IIKO version

```bash
sudo bash app/sst/check.sh
```

### Update SST-IIKO

```bash
# From the repository root
sudo bash app/sst/check.sh
# (follow prompts to check for updates)
```

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/sst-iiko/settings.ini` | SST-IIKO card reader configuration |
| `/etc/sst-iiko/print_settings.ini` | Fiscal printer template settings |
| `/etc/sst-iiko/templates/receipt.rtdf` | Receipt template (Russian locale) |
| `/etc/openvpn/client/pritunl.conf` | OpenVPN client configuration |
| `/etc/zabbix/zabbix_agentd.conf` | Zabbix agent configuration |
| `/etc/cups/cupsd.conf` | CUPS printing system configuration |

## Logging

Installation logs are written to:

```
/tmp/get_kiosk-lite/logs/kiosk_install.log
```

## Architecture

```
start.sh
  ├── Collects user selections via dialog --checklist
  ├── Generates package.sh with selected app/ scripts
  └── Executes package.sh (piped to tee for logging)

app/
  ├── proxyuser.sh   → /etc/sudoers.d/010_proxyuser-nopasswd
  ├── vpn.sh         → /etc/openvpn/client/pritunl.conf
  ├── hostname.sh    → /etc/hostname, /etc/hosts
  ├── sleep_off.sh   → systemd services (xsetoff, /opt/noblank.sh)
  ├── sst/           → sst-iiko package + settings.ini
  ├── terminals/     → udev rules + terminal integration scripts
  ├── fiscal/        → ATOL/SHTRIH driver + fiscal.env
  ├── printer/       → CUPS + printer driver + print_settings.ini
  ├── vnc/           → x11vnc service + systemd units
  └── zabbix/        → zabbix-agent + custom UserParameters
```

## Supported Hardware

### Payment Terminals

- Sberbank (various models)
- Inpas
- Arcus2

### Terminal Models

| Model | Vendor |
|-------|--------|
| P8 Unitoid | Sagem |
| KOZEN (TOUCH) | Kozen |
| VERIFONE | Verifone |
| Ingenica IPP320 | Sagem |
| PAX 300 | PAX |
| PAX SP30 | PAX |
| PAX IM20 | PAX |
| PAX CMF8 | PAX |

### Fiscal Printers

- ATOL RP series
- SHTRIH-M

### Supported Printers (CUPS)

- REXOD
- SAM4S 102c
- VKP80II (Custom)
- VKP80III (Custom)
- ATOL RP326
- POScenter RP-100 VCOM

## Troubleshooting

### Installer hangs at dialog prompt

Ensure `dialog` is installed and the terminal supports it:

```bash
apt-get -y install dialog
```

### SST-IIKO package not found

The `sst-iiko` package is pulled from a custom repository. Verify the APT source in `/etc/apt/sources.list.d/bos.list` matches your Debian version.

### Printer not detected (VCOM)

Check device permissions and udev rules:

```bash
ls -l /dev/ttyACM*
cat /etc/udev/rules.d/printer.rules
```

### VNC not connecting

Ensure the VNC service is enabled:

```bash
sudo systemctl status x11vnc
sudo systemctl status xorg
```

## Contributing

Contributions are welcome. Please ensure any new scripts follow the existing conventions:

- Use `#!/bin/bash` or `#!/bin/sh` shebang
- Include `sudo` explicitly for privileged commands
- Use `dialog` for interactive prompts (consistent with `start.sh`)
- Log output to `/tmp/get_kiosk-lite/logs/kiosk_install.log`

## License

<details>
<summary><strong>View license information</strong></summary>

Please check the `LICENSE` file in the repository root for details.

</details>
