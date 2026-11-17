//! Static device catalog: bank terminal udev ids, printer models, integrations.
//!
//! Values mirror `app/terminals/terminal.env` and `app/printer/vcom.env`
//! from the shell implementation.

/// TLS pin for `repo.getit.rest`, taken from the shell bootstrap.
pub const REPO_HOST: &str = "repo.getit.rest";
pub const REPO_FINGERPRINT: &str = "DA4C7079057FA9F747D216923860F4B26074FBFE";
pub const REPO_KEYRING: &str = "/etc/apt/keyrings/getit-repo-2026.gpg";

/// Prefix shared by every pinpad udev rule.
const PAD_RULE_BASE: &str = r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", SYMLINK+="pinpad", "#;

pub struct PadModel {
    /// udev match attributes appended to [`PAD_RULE_BASE`].
    pub attrs: &'static str,
}

/// Labels in checklist order, matching `app/terminals/setup.sh`.
pub const PAD_LABELS: [&str; 8] = [
    "P8 Unitoid",
    "KOZEN (TOUCH)",
    "VERIFONE",
    "Ingenica IPP320 (Sagem)",
    "PAX 300",
    "PAX SP30",
    "PAX IM20",
    "PAX CMF8",
];

/// Index-aligned with [`PAD_LABELS`].
pub const PAD_MODELS: [PadModel; 8] = [
    PadModel {
        attrs: r#"ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="2006""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="2012""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="11ca", ATTRS{idProduct}=="0219""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="079b", ATTRS{idProduct}=="0028""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="2fb8", ATTRS{idProduct}=="1102""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="9908", ATTRS{idProduct}=="9030""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="2fb8", ATTRS{idProduct}=="110c""#,
    },
    PadModel {
        attrs: r#"ATTRS{idVendor}=="2fb8", ATTRS{idProduct}=="0412""#,
    },
];

pub struct Integration {
    /// Directory under `app/terminals/`.
    pub dir: &'static str,
}

pub const INTEGRATION_LABELS: [&str; 3] = ["Sberbank", "Inpas", "Arcus"];

/// Index-aligned with [`INTEGRATION_LABELS`].
pub const INTEGRATIONS: [Integration; 3] = [
    Integration { dir: "sber" },
    Integration { dir: "inpas" },
    Integration { dir: "arcus2" },
];

pub struct PrinterModel {
    /// Driver directory under `app/printer/driver/`.
    pub dir: &'static str,
    /// udev rule that creates the VCOM symlink; `None` when `vcom.env` has no
    /// mapping for the model.
    pub vcom_rule: Option<&'static str>,
}

/// Labels in checklist order, matching `app/printer/setup.sh`.
pub const PRINTER_LABELS: [&str; 11] = [
    "REXOD (Universal)",
    "SAM4S 102c",
    "Custom VKP80II (2)",
    "Custom VKP80III (3)",
    "ATOL RP326",
    "POScenter RP-100 VCOM",
    "SEWOO Generic",
    "SEWOO SLK",
    "SEWOO LKT",
    "SEWOO Vendor",
    "SEWOO SLK II",
];

/// Index-aligned with [`PRINTER_LABELS`].
pub const PRINTER_MODELS: [PrinterModel; 11] = [
    PrinterModel {
        dir: "Universal",
        vcom_rule: None,
    },
    PrinterModel {
        dir: "Sam4s_102c",
        vcom_rule: Some(
            r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="1c8a", ATTRS{idProduct}=="3a38", SYMLINK+="printer""#,
        ),
    },
    PrinterModel {
        dir: "Custom_VKP80II_2",
        vcom_rule: Some(
            r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="2912", ATTRS{idProduct}=="0005", SYMLINK+="vcom_printer""#,
        ),
    },
    PrinterModel {
        dir: "Custom_VKP80III_3",
        vcom_rule: Some(
            r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="2912", ATTRS{idProduct}=="0005", SYMLINK+="vcom_printer""#,
        ),
    },
    PrinterModel {
        dir: "Atol_RP326",
        vcom_rule: None,
    },
    PrinterModel {
        dir: "POScenter_RP-100_VCOM",
        vcom_rule: Some(
            r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="2014", SYMLINK+="vcom_printer""#,
        ),
    },
    PrinterModel {
        dir: "SEWOO_generic",
        vcom_rule: None,
    },
    PrinterModel {
        dir: "SEWOO_SLK",
        vcom_rule: Some(
            r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="0525", ATTRS{idProduct}=="a700", SYMLINK+="printer""#,
        ),
    },
    PrinterModel {
        dir: "SEWOO_LKT",
        vcom_rule: None,
    },
    PrinterModel {
        dir: "SEWOO_vendor",
        vcom_rule: None,
    },
    PrinterModel {
        dir: "SEWOO_SLK_II",
        vcom_rule: None,
    },
];

pub const CONNECTIONS: [&str; 3] = ["USB", "VCOM", "NETWORK"];
pub const FISCAL_LABELS: [&str; 2] = ["Atol", "SHTRIH-M"];

/// Build the full udev rule for a pinpad model index.
pub fn pad_rule(model_index: usize) -> String {
    let model = PAD_MODELS.get(model_index).unwrap_or(&PAD_MODELS[0]);
    format!("{PAD_RULE_BASE}{}", model.attrs)
}
