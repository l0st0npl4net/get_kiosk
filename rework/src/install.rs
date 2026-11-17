//! Native implementations of every installer step.
//!
//! Each function mirrors one shell script from `app/`, keeping the same
//! commands, paths and ordering. Failures are non-fatal, like in the shell
//! originals which never used `set -e`.

use crate::assets;
use crate::catalog::{self, INTEGRATIONS, PRINTER_LABELS, PRINTER_MODELS};
use crate::exec::{Ctx, Shell};
use crate::steps::StepKind;
use crate::task::Answers;

const SETTINGS: &str = "/etc/sst-iiko/settings.ini";
const PRINT_SETTINGS: &str = "/etc/sst-iiko/print_settings.ini";
const TEMPLATES: &str = "/etc/sst-iiko/templates";

/// Run the installer body for one step.
pub async fn run(ctx: &Ctx, sh: &mut Shell, step: StepKind, ans: &Answers) {
    match step {
        StepKind::ProxyUser => proxy_user(sh).await,
        StepKind::Vpn => vpn(sh, ctx, ans.text(0)).await,
        StepKind::Hostname => hostname(sh, ans.text(0)).await,
        StepKind::SstRepo => sst_repo(sh, ctx).await,
        StepKind::SstSetup => sst_setup(sh, ans).await,
        StepKind::SleepOff => sleep_off(sh, ctx).await,
        StepKind::Terminal => terminal(sh, ctx, ans).await,
        StepKind::Fiscal => fiscal(sh, ctx, ans).await,
        StepKind::Printer => printer(sh, ctx, ans).await,
        StepKind::VncInstall => vnc_install(sh, ctx).await,
        StepKind::VncEnable => vnc_enable(sh).await,
        StepKind::VncDisable => vnc_disable(sh).await,
        StepKind::Zabbix => zabbix(sh, ctx, ans.text(0)).await,
    }
}

/// Read a shipped asset, logging the failure when it is missing.
async fn load(sh: &mut Shell, ctx: &Ctx, name: &str) -> Option<String> {
    match ctx.asset(name) {
        Ok(text) => Some(text),
        Err(e) => {
            sh.line(format!("! {e}")).await;
            None
        }
    }
}

/// Append a line to a root-owned file without shell interpolation surprises.
pub async fn append_root(sh: &mut Shell, path: &str, text: &str) -> bool {
    let script = format!(
        "sudo mkdir -p $(dirname {path}) && sudo tee -a {path} >/dev/null <<'KIOSK_APPEND'\n{text}\nKIOSK_APPEND"
    );
    let label = format!("append to {path}");
    sh.sh_quiet(&script, &label).await
}

/// Copy a resource tree from the repository into a system path.
pub async fn copy_tree(sh: &mut Shell, from: &std::path::Path, to: &str) -> bool {
    let script = format!(
        "sudo cp -r {} {to}",
        crate::exec::shell_quote(&from.display().to_string())
    );
    sh.sh(&script).await
}

async fn proxy_user(sh: &mut Shell) {
    sh.sh("sudo useradd -p proxyuser -s /bin/bash -m proxyuser")
        .await;
    sh.sh("echo 'proxyuser:proxyuser' | sudo chpasswd").await;
    sh.sh("sudo mkdir -p /home/proxyuser").await;
    sh.sh("sudo cp -rT /etc/skel /home/proxyuser").await;
    sh.sh("sudo chown -R proxyuser:proxyuser /home/proxyuser")
        .await;
    sh.sh("sudo chsh -s /bin/bash proxyuser").await;
    sh.line("PROXYUSER setup complete!").await;
}

async fn vpn(sh: &mut Shell, ctx: &Ctx, url: &str) {
    sh.run(&["sudo", "apt-get", "-y", "install", "openvpn"])
        .await;
    sh.sh(r#"sudo sed -i -e 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn"#)
        .await;

    let work = ctx.work();
    let work_s = work.display().to_string();
    sh.mkdir_root(&work_s).await;
    sh.sh(&format!("sudo chmod 777 {work_s}")).await;

    if url.trim().is_empty() {
        sh.line("! OpenVPN URL is empty, skipping profile download")
            .await;
        return;
    }

    let quoted = crate::exec::shell_quote(url.trim());
    sh.sh(&format!("wget {quoted} -P {work_s}")).await;
    sh.sh(&format!("unzip -o {work_s}/*zip -d {work_s}")).await;
    sh.sh(&format!(
        "sudo mkdir -p /etc/openvpn/client && sudo cp {work_s}/*.ovpn /etc/openvpn/client/pritunl.conf"
    ))
    .await;

    sh.run(&["sudo", "systemctl", "start", "openvpn-client@pritunl"])
        .await;
    sh.run(&["sudo", "systemctl", "enable", "openvpn-client@pritunl"])
        .await;
    sh.line("OpenVPN setup complete! (reboot required)").await;
}

async fn hostname(sh: &mut Shell, name: &str) {
    let name = name.trim();
    if name.is_empty() {
        sh.line("! hostname is empty, skipping").await;
        return;
    }
    let quoted = crate::exec::shell_quote(name);
    sh.sh(&format!("sudo hostnamectl set-hostname {quoted}"))
        .await;
    sh.sh(&format!(
        r#"sudo sed -i "s/127.0.1.1.*/127.0.1.1 {name}/" /etc/hosts"#
    ))
    .await;
    sh.sh("cat /etc/hostname /etc/hosts").await;
    sh.line("Hostname has changed! (reboot required)").await;
}

async fn sst_repo(sh: &mut Shell, _ctx: &Ctx) {
    // The expected OpenPGP fingerprint of the signing key is not in the
    // repository: start.sh exports it. Verify the downloaded `.gpg` key.
    let expected = std::env::var(catalog::REPO_KEY_FPR_ENV)
        .ok()
        .map(|v| v.trim().replace(':', "").to_ascii_uppercase())
        .filter(|v| v.len() == 40 && v.chars().all(|c| c.is_ascii_hexdigit()));

    let Some(expected) = expected else {
        sh.line(format!(
            "! {} is not set to a 40-character GPG fingerprint",
            catalog::REPO_KEY_FPR_ENV
        ))
        .await;
        sh.line("! refusing to add the repository").await;
        return;
    };

    sh.run(&["sudo", "apt-get", "-y", "install", "gnupg"]).await;

    let host = catalog::REPO_HOST;
    let staged = "/tmp/getit-repo-2026.gpg";

    sh.sh_quiet(
        &format!("wget -q -O {staged} https://{host}/{}", catalog::REPO_KEY),
        &format!("download {host}/{}", catalog::REPO_KEY),
    )
    .await;

    // `--show-keys` prints the fingerprint of the first key in the file.
    let got = sh
        .capture(&format!(
            "gpg --show-keys --with-colons {staged} 2>/dev/null | awk -F: '/^fpr/ {{ print $10; exit }}'"
        ))
        .await
        .map(|v| v.trim().to_ascii_uppercase());

    match got {
        Some(ref fpr) if *fpr == expected => {
            sh.line(format!("Signing key OK ({}…)", &expected[..16]))
                .await;
        }
        Some(fpr) => {
            sh.line(format!("! signing key fingerprint mismatch: got {fpr}"))
                .await;
            sh.line("! refusing to add the repository").await;
            sh.sh_quiet(&format!("rm -f {staged}"), &format!("rm -f {staged}"))
                .await;
            return;
        }
        None => {
            sh.line(format!("! cannot read the key fingerprint from {staged}"))
                .await;
            sh.sh_quiet(&format!("rm -f {staged}"), &format!("rm -f {staged}"))
                .await;
            return;
        }
    }

    let codename = sh
        .capture(". /etc/os-release && echo $VERSION_CODENAME")
        .await
        .unwrap_or_else(|| "bullseye".to_string());

    sh.mkdir_root("/etc/apt/keyrings").await;
    // Dearmor the file that was just verified; never re-fetch after the check.
    let dearmor = format!(
        "sudo gpg --yes --dearmor -o {keyring} < {staged}",
        keyring = catalog::REPO_KEYRING
    );
    sh.sh_quiet(&dearmor, "install repository keyring").await;
    sh.sh_quiet(&format!("rm -f {staged}"), &format!("rm -f {staged}"))
        .await;

    let list = format!(
        "deb [signed-by={}] https://{host}/ {codename} main\n",
        catalog::REPO_KEYRING
    );
    sh.write_root("/etc/apt/sources.list.d/bos.list", &list)
        .await;
}

async fn sst_setup(sh: &mut Shell, ans: &Answers) {
    let key = ans.text(0);
    let version = ans.text(1).trim().to_string();
    let kassa_ip = ans.text(2).trim().to_string();

    append_root(
        sh,
        "/etc/sudoers.d/010_proxyuser-nopasswd",
        "proxyuser ALL=(ALL) NOPASSWD: ALL",
    )
    .await;

    sh.mkdir_root("/home/proxyuser/.ssh").await;
    if !key.trim().is_empty() {
        sh.write_root(
            "/home/proxyuser/.ssh/authorized_keys",
            &format!("{}\n", key.trim()),
        )
        .await;
        sh.sh("sudo chown -R proxyuser:proxyuser /home/proxyuser/.ssh")
            .await;
        sh.sh("sudo chmod 700 /home/proxyuser/.ssh").await;
        sh.sh("sudo chmod 600 /home/proxyuser/.ssh/authorized_keys")
            .await;
    } else {
        sh.line("! no SSH key given, authorized_keys not written")
            .await;
    }

    sh.run(&["sudo", "apt-get", "-y", "install", "libtiff-dev"])
        .await;

    let debs: [(&str, &str); 4] = [
        (
            "/tmp/libtiff5-main.deb",
            "https://snapshot.debian.org/archive/debian/20221124T210835Z/pool/main/t/tiff/libtiff5_4.4.0-6_amd64.deb",
        ),
        (
            "/tmp/libicu67.deb",
            "https://snapshot.debian.org/archive/debian-security/20250615T141349Z/pool/updates/main/i/icu/libicu67_67.1-7%2Bdeb11u1_amd64.deb",
        ),
        (
            "/tmp/libssl1.1.deb",
            "https://snapshot.debian.org/archive/debian-security/20260615T025018Z/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0%2Bdeb11u8_amd64.deb",
        ),
        (
            "/tmp/libtiff5-dev.deb",
            "http://ftp.ru.debian.org/debian/pool/main/t/tiff/libtiff5-dev_4.7.2-1_amd64.deb",
        ),
    ];
    for (path, url) in debs {
        sh.run(&["sudo", "wget", "-O", path, url]).await;
    }
    for path in [
        "/tmp/libtiff5-dev.deb",
        "/tmp/libicu67.deb",
        "/tmp/libssl1.1.deb",
        "/tmp/libtiff5-main.deb",
    ] {
        sh.run(&["sudo", "dpkg", "-i", path]).await;
    }

    let codename = sh
        .capture(". /etc/os-release && echo $VERSION_CODENAME")
        .await
        .unwrap_or_else(|| "bullseye".to_string());
    let sources = format!(
        "deb http://mirror.yandex.ru/debian {codename} main contrib non-free\n\
         deb http://mirror.yandex.ru/debian {codename}-updates main contrib non-free\n\
         deb http://security.debian.org/debian-security {codename}-security main contrib non-free\n"
    );
    sh.write_root("/etc/apt/sources.list", &sources).await;
    sh.run(&["sudo", "apt-get", "update"]).await;

    if version.is_empty() {
        sh.run(&["sudo", "apt-get", "-y", "install", "sst-iiko"])
            .await;
    } else {
        sh.sh(&format!(
            "sudo apt-get -y install {}",
            crate::exec::shell_quote(&format!("sst-iiko={version}*"))
        ))
        .await;
    }

    sh.sh(
        "sudo ln -sf /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.6",
    )
    .await;

    sh.run(&["sudo", "systemctl", "enable", "sst-iiko"]).await;
    sh.run(&["sudo", "systemctl", "start", "sst-iiko"]).await;

    sh.run(&["sudo", "crudini", "--set", SETTINGS, "FP", "type", "Dummy"])
        .await;
    if is_valid_host(&kassa_ip) {
        sh.sh(&format!(
            "sudo crudini --set {SETTINGS} iiko host {}",
            crate::exec::shell_quote(&format!("ws://{kassa_ip}"))
        ))
        .await;
    } else {
        sh.line(format!(
            "! kassa IP \"{kassa_ip}\" is not a valid host, iiko host not set"
        ))
        .await;
    }

    sh.mkdir_root("/opt/sst-iiko/img").await;
    sh.mkdir_root(TEMPLATES).await;
    sh.sh(&format!("sudo touch {TEMPLATES}/header")).await;
    sh.run(&[
        "sudo",
        "systemctl",
        "enable",
        "systemd-networkd-wait-online.service",
    ])
    .await;

    sh.line("GET KIOSK SOFTWARE setup complete!").await;
}

async fn sleep_off(sh: &mut Shell, ctx: &Ctx) {
    sh.run(&["sudo", "apt-get", "update"]).await;
    sh.run(&["sudo", "apt-get", "install", "-y", "x11-xserver-utils"])
        .await;

    let (Some(unit), Some(noblank), Some(display)) = (
        load(sh, ctx, assets::XSETOFF_SERVICE).await,
        load(sh, ctx, assets::NOBLANK_SH).await,
        load(sh, ctx, assets::DISPLAY_CONF).await,
    ) else {
        return;
    };

    sh.write_root("/lib/systemd/system/xsetoff.service", &unit)
        .await;
    sh.write_root("/opt/noblank.sh", &noblank).await;
    sh.sh("sudo chmod +x /opt/noblank.sh").await;
    sh.write_root("/usr/share/X11/xorg.conf.d/99-display.conf", &display)
        .await;

    sh.sh("sudo chmod 777 -R /opt/").await;
    sh.run(&["sudo", "systemctl", "enable", "xsetoff"]).await;
    sh.run(&["sudo", "systemctl", "start", "xsetoff"]).await;
    sh.run(&["sudo", "systemctl", "daemon-reload"]).await;
}

async fn terminal(sh: &mut Shell, ctx: &Ctx, ans: &Answers) {
    let integration = ans.choice(0);
    let model = ans.choice(1);

    let rule = catalog::pad_rule(model);
    append_root(sh, "/etc/udev/rules.d/10-pinpad.rules", &rule).await;
    sh.run(&["sudo", "udevadm", "control", "--reload-rules"])
        .await;
    sh.run(&["sudo", "udevadm", "trigger"]).await;

    let dir = INTEGRATIONS
        .get(integration)
        .map(|i| i.dir)
        .unwrap_or(INTEGRATIONS[0].dir);
    let script = ctx.app().join("terminals").join(dir);

    match dir {
        "sber" => sber(sh, ctx).await,
        "inpas" => inpas(sh, ctx).await,
        _ => arcus(sh, ctx).await,
    }

    sh.line(format!("terminal integration source: {}", script.display()))
        .await;
}

async fn sber(sh: &mut Shell, ctx: &Ctx) {
    let platforms = ctx.app().join("terminals").join("sber").join("platforms");
    copy_tree(sh, &platforms, "/opt/sst-iiko/").await;
    sh.sh("sudo chmod 777 -R /opt/sst-iiko/").await;
    sh.sh("sudo rm -f /opt/sst-iiko/platforms/ELF32_80386/ttyS99")
        .await;
    sh.sh("sudo ln -sf /dev/pinpad /opt/sst-iiko/platforms/ELF32_80386/ttyS99")
        .await;
    sh.run(&["sudo", "/opt/sst-iiko/platforms/ELF32_80386/sb_pilot", "7"])
        .await;

    let base = "/opt/sst-iiko/platforms/ELF32_80386";
    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        SETTINGS,
        "Terminal",
        "binfile",
        "sb_pilot",
        "--set",
        SETTINGS,
        "Terminal",
        "delay",
        "3000",
        "--set",
        SETTINGS,
        "Terminal",
        "instantMode",
        "false",
        "--set",
        SETTINGS,
        "Terminal",
        "path",
        base,
        "--set",
        SETTINGS,
        "Terminal",
        "relative",
        "false",
        "--set",
        SETTINGS,
        "Terminal",
        "type",
        "Sberbank",
    ])
    .await;
    normalize_ini(sh).await;
    sh.line("SBERBANK TERMINAL setup complete!").await;
}

async fn inpas(sh: &mut Shell, ctx: &Ctx) {
    sh.run(&["sudo", "apt-get", "-y", "install", "default-jdk"])
        .await;

    let svc = ctx
        .app()
        .join("terminals")
        .join("inpas")
        .join("DC_Linux_Service");
    let svc_s = svc.display().to_string();
    sh.sh(&format!("sudo chmod 777 -R {svc_s}")).await;
    sh.sh(&format!("sudo chmod +x {svc_s}/service.sh")).await;
    sh.sh(&format!("sudo {svc_s}/service.sh install")).await;

    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        SETTINGS,
        "Terminal",
        "terminalID",
        "--set",
        SETTINGS,
        "Terminal",
        "type",
        "DualConnector",
    ])
    .await;
    normalize_ini(sh).await;
    sh.run(&["sudo", "service", "dualconnector", "start"]).await;
    sh.line("DUALCONNECTOR setup complete!").await;
}

async fn arcus(sh: &mut Shell, ctx: &Ctx) {
    sh.mkdir_root("/home/reg").await;
    let driver = ctx.app().join("terminals").join("arcus2").join("driver");
    copy_tree(sh, &driver, "/home/reg/").await;
    sh.sh("sudo chmod 777 -R /home/reg").await;

    sh.run(&["sudo", "dpkg", "--add-architecture", "i386"])
        .await;
    sh.run(&["sudo", "apt-get", "update"]).await;
    sh.run(&[
        "sudo",
        "apt-get",
        "-y",
        "install",
        "libc6:i386",
        "libstdc++6:i386",
    ])
    .await;

    let debs: [(&str, &str); 6] = [
        (
            "/tmp/libncurses5_6.4-4_amd64.deb",
            "http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libncurses5_6.4-4_amd64.deb",
        ),
        (
            "/tmp/libncurses5_6.4-4_i386.deb",
            "http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libncurses5_6.4-4_i386.deb",
        ),
        (
            "/tmp/libstdc++5_3.3.6-34_amd64.deb",
            "http://ftp.ru.debian.org/debian/pool/main/g/gcc-3.3/libstdc++5_3.3.6-34_amd64.deb",
        ),
        (
            "/tmp/libstdc++5_3.3.6-34_i386.deb",
            "http://ftp.ru.debian.org/debian/pool/main/g/gcc-3.3/libstdc++5_3.3.6-34_i386.deb",
        ),
        (
            "/tmp/libtinfo5_6.4-4_amd64.deb",
            "http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.4-4_amd64.deb",
        ),
        (
            "/tmp/libtinfo5_6.4-4_i386.deb",
            "http://ftp.ru.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.4-4_i386.deb",
        ),
    ];
    for (path, url) in debs {
        sh.run(&["sudo", "wget", "-O", path, url]).await;
    }
    for path in [
        "/tmp/libtinfo5_6.4-4_amd64.deb",
        "/tmp/libtinfo5_6.4-4_i386.deb",
        "/tmp/libncurses5_6.4-4_amd64.deb",
        "/tmp/libncurses5_6.4-4_i386.deb",
        "/tmp/libstdc++5_3.3.6-34_amd64.deb",
        "/tmp/libstdc++5_3.3.6-34_i386.deb",
    ] {
        sh.run(&["sudo", "dpkg", "-i", path]).await;
    }

    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        SETTINGS,
        "Terminal",
        "path",
        "/home/reg/arcus/cashreg",
        "--set",
        SETTINGS,
        "Terminal",
        "receiptPath",
        "/home/reg/arcus/cpd.out",
        "--set",
        SETTINGS,
        "Terminal",
        "answerPath",
        "/home/reg/arcus/rc.out",
        "--set",
        SETTINGS,
        "Terminal",
        "type",
        "Arcus",
    ])
    .await;
    normalize_ini(sh).await;
    sh.run(&["sudo", "/home/reg/arcus/cashreg", "/o7"]).await;
    sh.line("ARCUS TERMINAL setup complete!").await;
}

async fn fiscal(sh: &mut Shell, ctx: &Ctx, ans: &Answers) {
    match ans.choice(0) {
        0 => atol(sh, ctx, ans.text(1)).await,
        _ => shtrih(sh).await,
    }
}

async fn atol(sh: &mut Shell, ctx: &Ctx, version: &str) {
    let version = version.trim();
    if version.is_empty() {
        sh.line("! ATOL version is empty, skipping package install")
            .await;
    } else {
        sh.sh(&format!(
            "sudo apt-get -y install {}",
            crate::exec::shell_quote(&format!("fptr10-test-util={version}"))
        ))
        .await;
    }

    sh.run(&["sudo", "crudini", "--set", SETTINGS, "FP", "type", "Atol"])
        .await;
    normalize_ini(sh).await;
    write_atol_template(sh, ctx).await;
    sh.line("ATOL driver setup complete!").await;
}

async fn shtrih(sh: &mut Shell) {
    const RULE: &str = r#"KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0083", SYMLINK+="shtrih""#;
    append_root(sh, "/etc/udev/rules.d/shtrih.rules", RULE).await;

    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        SETTINGS,
        "FP",
        "password",
        "30",
        "--set",
        SETTINGS,
        "FP",
        "port",
        "/dev/shtrih",
        "--set",
        SETTINGS,
        "FP",
        "summType",
        "Summ2",
        "--set",
        SETTINGS,
        "FP",
        "timeout",
        "15000",
        "--set",
        SETTINGS,
        "FP",
        "type",
        "Shtrikh",
    ])
    .await;
    normalize_ini(sh).await;
    sh.line("SHTRIH-M setup complete!").await;
}

async fn write_atol_template(sh: &mut Shell, ctx: &Ctx) {
    let path = format!("{TEMPLATES}/postfiscalAtol.rtdf");
    let exists = sh
        .capture(&format!("test -f {path} && echo yes"))
        .await
        .is_some();
    if exists {
        sh.line(format!("{path} - Already exists!")).await;
        return;
    }
    let Some(template) = load(sh, ctx, assets::POSTFISCAL_ATOL_RTDF).await else {
        return;
    };
    sh.mkdir_root(TEMPLATES).await;
    sh.write_root(&path, &template).await;
}

async fn printer(sh: &mut Shell, ctx: &Ctx, ans: &Answers) {
    sh.run(&["sudo", "apt-get", "-y", "install", "cups"]).await;
    sh.run(&[
        "sudo",
        "apt-get",
        "-y",
        "install",
        "foomatic-db",
        "foomatic-db-engine",
    ])
    .await;

    let Some(cupsd) = load(sh, ctx, assets::CUPSD_CONF).await else {
        return;
    };
    sh.write_root("/etc/cups/cupsd.conf", &cupsd).await;

    if sh
        .capture(&format!("test -f {PRINT_SETTINGS} && echo yes"))
        .await
        .is_some()
    {
        sh.line(format!("{PRINT_SETTINGS} - Already exists!")).await;
    } else if let Some(settings) = load(sh, ctx, assets::PRINT_SETTINGS_INI).await {
        sh.write_root(PRINT_SETTINGS, &settings).await;
    }

    if sh
        .capture(&format!("test -d {TEMPLATES} && echo yes"))
        .await
        .is_some()
    {
        sh.line(format!("{TEMPLATES} - Already exists!")).await;
    } else {
        sh.mkdir_root(TEMPLATES).await;
        if let Some(receipt) = load(sh, ctx, assets::RECEIPT_RTDF).await {
            sh.write_root(&format!("{TEMPLATES}/receipt.rtdf"), &receipt)
                .await;
        }
    }

    if sh
        .capture(&format!(
            "test -f {TEMPLATES}/postfiscalAtol.rtdf && echo yes"
        ))
        .await
        .is_some()
    {
        sh.line(format!("{TEMPLATES}/postfiscalAtol.rtdf - Already exists!"))
            .await;
    } else if let Some(template) = load(sh, ctx, assets::POSTFISCAL_ATOL_RTDF).await {
        sh.write_root(&format!("{TEMPLATES}/postfiscalAtol.rtdf"), &template)
            .await;
    }

    let model_index = ans.choice(0);
    let model = PRINTER_MODELS
        .get(model_index)
        .unwrap_or(&PRINTER_MODELS[0]);

    let filter = ctx
        .app()
        .join("printer")
        .join("driver")
        .join(model.dir)
        .join("raster_to_printer");
    copy_tree(sh, &filter, "/usr/lib/cups/filter/").await;
    sh.sh("sudo chmod a+x /usr/lib/cups/filter/raster_to_printer")
        .await;
    sh.sh("sync").await;

    let connection = catalog::CONNECTIONS
        .get(ans.choice(1))
        .copied()
        .unwrap_or("USB");

    let uri = match connection {
        "VCOM" => {
            if let Some(rule) = model.vcom_rule {
                append_root(sh, "/etc/udev/rules.d/printer.rules", rule).await;
            } else {
                let label = PRINTER_LABELS
                    .get(model_index)
                    .copied()
                    .unwrap_or("printer");
                sh.line(format!(
                    "! {label} has no VCOM rule, /dev/printer will not be created"
                ))
                .await;
            }
            if let Some(rc_local) = load(sh, ctx, assets::RC_LOCAL).await {
                sh.write_root("/etc/rc.local", &rc_local).await;
                sh.sh("sudo chmod +x /etc/rc.local").await;
            }
            if let Some(service) = load(sh, ctx, assets::RC_LOCAL_SERVICE).await {
                sh.write_root("/etc/systemd/system/rc-local.service", &service)
                    .await;
            }
            sh.run(&["sudo", "systemctl", "enable", "rc-local"]).await;
            sh.run(&["sudo", "systemctl", "restart", "rc-local"]).await;
            "serial:/dev/printer?baud=115200".to_string()
        }
        "NETWORK" => {
            let ip = ans.text(2).trim();
            let port = ans.text(3).trim();
            let port_ok = !port.is_empty() && port.chars().all(|c| c.is_ascii_digit());
            if !is_valid_host(ip) || !port_ok {
                sh.line(format!(
                    "! printer address \"{ip}:{port}\" is invalid, printer not registered"
                ))
                .await;
                return;
            }
            format!("socket://{ip}:{port}")
        }
        _ => {
            let direct = sh.capture(r#"sudo lpinfo -v | grep "direct usb""#).await;
            match direct {
                Some(list) => list
                    .lines()
                    .next()
                    .and_then(|l| l.split_whitespace().last())
                    .unwrap_or("")
                    .to_string(),
                None => String::new(),
            }
        }
    };

    if uri.is_empty() {
        sh.line("! no direct USB printer reported by lpinfo, printer not registered")
            .await;
        return;
    }

    sh.sh(&format!(
        "sudo lpadmin -x {}",
        crate::exec::shell_quote(model.dir)
    ))
    .await;

    let ppd = ctx
        .app()
        .join("printer")
        .join("driver")
        .join(model.dir)
        .join("driver.ppd");
    sh.sh(&format!(
        "sudo lpadmin -p {} -E -v {} -P {}",
        crate::exec::shell_quote(model.dir),
        crate::exec::shell_quote(&uri),
        crate::exec::shell_quote(&ppd.display().to_string())
    ))
    .await;

    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        PRINT_SETTINGS,
        "Document",
        "Printer",
        model.dir,
    ])
    .await;

    sh.run(&[
        "sudo",
        "crudini",
        "--set",
        SETTINGS,
        "FP",
        r"printer\SETTINGS_PATH",
        PRINT_SETTINGS,
        "--set",
        SETTINGS,
        "FP",
        r"printer\TEMPLATE_PATH",
        "/etc/sst-iiko/templates/",
        "--set",
        SETTINGS,
        "FP",
        r"printer\advancedTemplates",
        "true",
        "--set",
        SETTINGS,
        "FP",
        r"printer\type",
        "System",
        "--set",
        SETTINGS,
        "FP",
        "type",
        "Compound",
    ])
    .await;

    normalize_ini(sh).await;
    sh.line("Printer almost setup complete!").await;
}

async fn vnc_install(sh: &mut Shell, ctx: &Ctx) {
    sh.run(&["sudo", "apt-get", "-y", "install", "x11vnc"])
        .await;
    sh.run(&[
        "sudo",
        "x11vnc",
        "-storepasswd",
        "passw0rd",
        "/etc/x11vnc.pass",
    ])
    .await;

    if let Some(unit) = load(sh, ctx, assets::X11VNC_SERVICE).await {
        sh.write_root("/lib/systemd/system/x11vnc.service", &unit)
            .await;
    }
    if let Some(unit) = load(sh, ctx, assets::XORG_SERVICE).await {
        sh.write_root("/lib/systemd/system/xorg.service", &unit)
            .await;
    }
    sh.line("X11VNC setup complete!").await;
}

async fn vnc_enable(sh: &mut Shell) {
    for unit in ["x11vnc.service", "xorg.service", "xsst-iiko"] {
        sh.run(&["sudo", "systemctl", "enable", unit]).await;
    }
    sh.run(&["sudo", "systemctl", "start", "xsst-iiko"]).await;
    sh.run(&["sudo", "systemctl", "disable", "sst-iiko"]).await;
    sh.run(&["sudo", "systemctl", "start", "xorg.service"])
        .await;
    sh.run(&["sudo", "systemctl", "start", "x11vnc"]).await;
    sh.line("VNC mode enabled").await;
}

async fn vnc_disable(sh: &mut Shell) {
    for unit in ["x11vnc.service", "xorg.service", "xsst-iiko"] {
        sh.run(&["sudo", "systemctl", "disable", unit]).await;
    }
    sh.run(&["sudo", "systemctl", "stop", "xorg.service"]).await;
    sh.run(&["sudo", "systemctl", "stop", "x11vnc"]).await;
    sh.run(&["sudo", "systemctl", "enable", "sst-iiko"]).await;
    sh.run(&["sudo", "systemctl", "start", "sst-iiko"]).await;
    sh.line("Direct display mode restored").await;
}

async fn zabbix(sh: &mut Shell, ctx: &Ctx, name: &str) {
    sh.run(&["sudo", "apt-get", "update"]).await;
    sh.run(&["sudo", "apt-get", "-y", "install", "zabbix-agent", "curl"])
        .await;
    sh.run(&["sudo", "apt-get", "-y", "install", "coreutils"])
        .await;

    let name = if name.trim().is_empty() {
        "kiosk".to_string()
    } else {
        name.trim().to_string()
    };
    let Some(template) = load(sh, ctx, assets::ZABBIX_AGENTD_CONF).await else {
        return;
    };
    let conf = template.replace(assets::ZABBIX_HOSTNAME_SLOT, &name);
    sh.write_root("/etc/zabbix/zabbix_agentd.conf", &conf).await;

    sh.mkdir_root("/etc/zabbix/scripts").await;
    sh.write_root(
        "/etc/zabbix/scripts/status-check.sh",
        "curl -s -o /dev/null -w \"%{http_code}\" http://localhost:10000\n",
    )
    .await;
    sh.write_root(
        "/etc/zabbix/scripts/hardware-status-net.sh",
        "curl -s http://localhost:10000 | grep Network\n",
    )
    .await;
    sh.write_root(
        "/etc/zabbix/scripts/hardware-status-print.sh",
        "curl -s http://localhost:10000 | grep Print\n",
    )
    .await;
    sh.write_root(
        "/etc/zabbix/scripts/hardware-status-terminal.sh",
        "curl -s http://localhost:10000 | grep Terminal\n",
    )
    .await;

    sh.sh("sudo chown -R proxyuser:proxyuser /etc/zabbix/zabbix_agentd.conf.d")
        .await;
    sh.sh("sudo chown -R proxyuser:proxyuser /etc/zabbix/scripts")
        .await;

    let params = [
        ("status-check", "/etc/zabbix/scripts/status-check.sh"),
        (
            "hardware-status-net",
            "/etc/zabbix/scripts/hardware-status-net.sh",
        ),
        (
            "hardware-status-print",
            "/etc/zabbix/scripts/hardware-status-print.sh",
        ),
        (
            "hardware-status-terminal",
            "/etc/zabbix/scripts/hardware-status-terminal.sh",
        ),
    ];
    for (key, path) in params {
        append_root(
            sh,
            "/etc/zabbix/zabbix_agentd.conf.d/staus-check.conf",
            &format!("UserParameter={key},{path}"),
        )
        .await;
    }

    sh.run(&["sudo", "service", "zabbix-agent", "restart"])
        .await;
    sh.line("Zabbix agent setup complete!").await;
}

/// Accept only host names and IPv4 addresses so the value can be handed to
/// `crudini` and embedded in a `ws://` URL without escaping.
fn is_valid_host(value: &str) -> bool {
    let v = value.trim();
    if v.is_empty() || v.len() > 253 {
        return false;
    }
    v.chars()
        .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_'))
}

/// Normalize `key = value` spacing, as `sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g"`.
async fn normalize_ini(sh: &mut Shell) {
    sh.sh(&format!(
        r#"sudo sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" {SETTINGS}"#
    ))
    .await;
}
