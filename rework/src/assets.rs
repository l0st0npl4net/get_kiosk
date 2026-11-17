//! Configuration payloads shipped next to the binary.
//!
//! A release archive contains the binary, the `assets/` directory and the
//! `app/` payload it needs, so nothing is compiled into the executable. The
//! installer resolves both directories from its own location.

use std::path::{Path, PathBuf};

use color_eyre::eyre::{Result, eyre};

pub const CUPSD_CONF: &str = "cupsd.conf";
pub const PRINT_SETTINGS_INI: &str = "print_settings.ini";
pub const RECEIPT_RTDF: &str = "receipt.rtdf";
pub const POSTFISCAL_ATOL_RTDF: &str = "postfiscal_atol.rtdf";
pub const XSETOFF_SERVICE: &str = "xsetoff.service";
pub const NOBLANK_SH: &str = "noblank.sh";
pub const DISPLAY_CONF: &str = "99-display.conf";
pub const X11VNC_SERVICE: &str = "x11vnc.service";
pub const XORG_SERVICE: &str = "xorg.service";
pub const RC_LOCAL: &str = "rc.local";
pub const RC_LOCAL_SERVICE: &str = "rc-local.service";
pub const ZABBIX_AGENTD_CONF: &str = "zabbix_agentd.conf";

/// Zabbix agent hostname placeholder.
pub const ZABBIX_HOSTNAME_SLOT: &str = "__KIOSK_NAME__";

/// Read an asset by file name from the `assets/` directory.
pub fn load(assets_dir: &Path, name: &str) -> Result<String> {
    let path = assets_dir.join(name);
    std::fs::read_to_string(&path).map_err(|e| eyre!("cannot read asset {}: {e}", path.display()))
}

/// Locate `assets/` next to the executable, then next to `KIOSK_ROOT`.
pub fn locate_assets(exe_dir: &Path, root: &Path) -> Result<PathBuf> {
    let candidates = [exe_dir.join("assets"), root.join("rework").join("assets")];
    for dir in candidates {
        if dir.is_dir() {
            return Ok(dir);
        }
    }
    Err(eyre!(
        "cannot find assets/ next to the installer or inside the checkout"
    ))
}
