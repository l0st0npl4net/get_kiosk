//! Installer step definitions: which step exists and which values it needs.

use crate::catalog;

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum StepKind {
    ProxyUser,
    Vpn,
    Hostname,
    SstRepo,
    SstSetup,
    SleepOff,
    Terminal,
    Fiscal,
    Printer,
    VncInstall,
    VncEnable,
    VncDisable,
    Zabbix,
}

pub enum Field {
    Text {
        label: &'static str,
        hint: &'static str,
    },
    Choose {
        label: &'static str,
        options: &'static [&'static str],
    },
}

impl StepKind {
    /// Menu order of the original `dialog --checklist`.
    /// Menu order of the original `dialog --checklist`.
    pub const ALL: [StepKind; 13] = [
        StepKind::ProxyUser,
        StepKind::Vpn,
        StepKind::Hostname,
        StepKind::SstRepo,
        StepKind::SstSetup,
        StepKind::SleepOff,
        StepKind::Terminal,
        StepKind::Fiscal,
        StepKind::Printer,
        StepKind::VncInstall,
        StepKind::VncEnable,
        StepKind::VncDisable,
        StepKind::Zabbix,
    ];

    pub fn title(self) -> &'static str {
        match self {
            StepKind::ProxyUser => "Proxy user",
            StepKind::Vpn => "OpenVPN",
            StepKind::Hostname => "Hostname",
            StepKind::SstRepo => "GetIt repo",
            StepKind::SstSetup => "Get-Kiosk setup",
            StepKind::SleepOff => "Sleep off",
            StepKind::Terminal => "Bank terminal",
            StepKind::Fiscal => "Fiscal device",
            StepKind::Printer => "Receipt printer",
            StepKind::VncInstall => "VNC install",
            StepKind::VncEnable => "VNC enable",
            StepKind::VncDisable => "VNC disable",
            StepKind::Zabbix => "Zabbix agent",
        }
    }

    pub fn summary(self) -> &'static str {
        match self {
            StepKind::ProxyUser => "proxyuser account with passwordless sudo",
            StepKind::Vpn => "OpenVPN client with remote profile",
            StepKind::Hostname => "set hostname and /etc/hosts entry",
            StepKind::SstRepo => "TLS-pinned GetIt apt repository",
            StepKind::SstSetup => "SST-IIKO card reader software and config",
            StepKind::SleepOff => "disable DPMS and screen blanking",
            StepKind::Terminal => "pinpad udev rule plus bank integration",
            StepKind::Fiscal => "ATOL or SHTRIH-M fiscal driver",
            StepKind::Printer => "CUPS printer with selected driver",
            StepKind::VncInstall => "install x11vnc and systemd units",
            StepKind::VncEnable => "switch to VNC remote display",
            StepKind::VncDisable => "revert to direct display",
            StepKind::Zabbix => "zabbix agent with kiosk checks",
        }
    }

    pub fn fields(self) -> Vec<Field> {
        match self {
            StepKind::Vpn => vec![Field::Text {
                label: "OpenVPN config URL",
                hint: "zip archive with a .ovpn profile",
            }],
            StepKind::Hostname => vec![Field::Text {
                label: "New hostname",
                hint: "for example kiosk-01",
            }],
            StepKind::SstSetup => vec![
                Field::Text {
                    label: "Authorized SSH key",
                    hint: "public key for proxyuser",
                },
                Field::Text {
                    label: "SST-IIKO version",
                    hint: "empty = latest release",
                },
                Field::Text {
                    label: "Main kassa IP",
                    hint: "iiko server address",
                },
            ],
            StepKind::Terminal => vec![
                Field::Choose {
                    label: "Integration",
                    options: &catalog::INTEGRATION_LABELS,
                },
                Field::Choose {
                    label: "Terminal model",
                    options: &catalog::PAD_LABELS,
                },
            ],
            StepKind::Fiscal => vec![
                Field::Choose {
                    label: "Device",
                    options: &catalog::FISCAL_LABELS,
                },
                Field::Text {
                    label: "ATOL test-driver version",
                    hint: "empty = latest release",
                },
            ],
            StepKind::Printer => vec![
                Field::Choose {
                    label: "Printer model",
                    options: &catalog::PRINTER_LABELS,
                },
                Field::Choose {
                    label: "Connection",
                    options: &catalog::CONNECTIONS,
                },
                Field::Text {
                    label: "Printer IP",
                    hint: "NETWORK only",
                },
                Field::Text {
                    label: "Printer port",
                    hint: "NETWORK only",
                },
            ],
            StepKind::Zabbix => vec![Field::Text {
                label: "Kiosk name for Zabbix",
                hint: "agent Hostname value",
            }],
            _ => Vec::new(),
        }
    }
}
