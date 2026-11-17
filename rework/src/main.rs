//! GET-KIOSK installer, Ratatui rewrite.
//!
//! Releases ship as a zip containing the binary, the `assets/` text payloads
//! and the `app/` driver tree. `start.sh` unpacks that archive and executes the
//! binary as root.

mod app;
mod assets;
mod catalog;
mod exec;
mod install;
mod steps;
mod task;
mod ui;

use std::path::{Path, PathBuf};

use color_eyre::eyre::{Result, eyre};

use crate::app::App;
use crate::exec::Ctx;

fn main() -> Result<()> {
    color_eyre::install()?;
    let ctx = build_ctx()?;

    let runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .map_err(|e| eyre!("cannot start tokio runtime: {e}"))?;

    ratatui::run(|terminal| {
        let mut app = App::new(ctx.clone());
        runtime.block_on(app.run(terminal))
    })
}

/// Resolve the checkout root, asset directory and log path.
fn build_ctx() -> Result<Ctx> {
    let exe_dir = std::env::current_exe()?
        .parent()
        .map(Path::to_path_buf)
        .unwrap_or_else(|| PathBuf::from("/"));

    let repo_root = match env_path("KIOSK_ROOT") {
        Some(path) => path,
        None => resolve_root(&exe_dir)?,
    };

    let assets_dir = match env_path("KIOSK_ASSETS") {
        Some(path) => path,
        None => assets::locate_assets(&exe_dir, &repo_root)?,
    };

    let log_path = env_path("KIOSK_LOG").unwrap_or_else(|| PathBuf::from("/tmp/kiosk_install.log"));

    Ok(Ctx {
        repo_root,
        assets_dir,
        log_path,
    })
}

fn env_path(name: &str) -> Option<PathBuf> {
    match std::env::var(name) {
        Ok(value) if !value.trim().is_empty() => Some(PathBuf::from(value)),
        _ => None,
    }
}

/// The archive root is both the checkout and the binary directory, so check the
/// executable directory first, then walk up a few levels for a source checkout.
fn resolve_root(exe_dir: &Path) -> Result<PathBuf> {
    if exe_dir.join("app").is_dir() {
        return Ok(exe_dir.to_path_buf());
    }
    let mut candidate = exe_dir;
    for _ in 0..4 {
        match candidate.parent() {
            Some(parent) => candidate = parent,
            None => break,
        }
        if candidate.join("app").is_dir() {
            return Ok(candidate.to_path_buf());
        }
    }
    let cwd = std::env::current_dir()?;
    if cwd.join("app").is_dir() {
        return Ok(cwd);
    }
    Err(eyre!(
        "cannot locate app/, set KIOSK_ROOT to the unpacked release directory"
    ))
}
