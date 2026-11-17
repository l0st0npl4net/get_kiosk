//! Configuration payloads embedded into the binary.
//!
//! Driver binaries, PPDs and vendor archives stay in `app/` and are copied at
//! run time; only text payloads live here so the installer cannot drift from
//! its own resources.

pub const CUPSD_CONF: &str = include_str!("../assets/cupsd.conf");
pub const PRINT_SETTINGS_INI: &str = include_str!("../assets/print_settings.ini");
pub const RECEIPT_RTDF: &str = include_str!("../assets/receipt.rtdf");
pub const POSTFISCAL_ATOL_RTDF: &str = include_str!("../assets/postfiscal_atol.rtdf");
pub const XSETOFF_SERVICE: &str = include_str!("../assets/xsetoff.service");
pub const NOBLANK_SH: &str = include_str!("../assets/noblank.sh");
pub const DISPLAY_CONF: &str = include_str!("../assets/99-display.conf");
pub const X11VNC_SERVICE: &str = include_str!("../assets/x11vnc.service");
pub const XORG_SERVICE: &str = include_str!("../assets/xorg.service");
pub const RC_LOCAL: &str = include_str!("../assets/rc.local");
pub const RC_LOCAL_SERVICE: &str = include_str!("../assets/rc-local.service");
pub const ZABBIX_AGENTD_CONF: &str = include_str!("../assets/zabbix_agentd.conf");

/// Zabbix agent hostname placeholder.
pub const ZABBIX_HOSTNAME_SLOT: &str = "__KIOSK_NAME__";
