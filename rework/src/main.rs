//! GET-KIOSK installer, Ratatui rewrite.
//!
//! The entry point is the shell script `start.sh`, which installs the build
//! dependencies, compiles this crate and executes the binary as root.

mod app;
mod assets;
mod catalog;
mod exec;
mod install;
mod steps;
mod task;
mod ui;

use std::path::PathBuf;

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

/// Resolve the repository root and log path from the environment or the
/// binary location.
fn build_ctx() -> Result<Ctx> {
    let root = match std::env::var("KIOSK_ROOT") {
        Ok(value) if !value.trim().is_empty() => PathBuf::from(value),
        _ => resolve_root()?,
    };
    let log_path = match std::env::var("KIOSK_LOG") {
        Ok(value) if !value.trim().is_empty() => PathBuf::from(value),
        _ => PathBuf::from("/tmp/kiosk_install.log"),
    };
    Ok(Ctx {
        repo_root: root,
        log_path,
    })
}

fn resolve_root() -> Result<PathBuf> {
    let exe = std::env::current_exe()?;
    // rework/target/release/kiosk-installer -> repository root
    let mut candidate = exe.as_path();
    for _ in 0..4 {
        if let Some(parent) = candidate.parent() {
            candidate = parent;
            if candidate.join("app").is_dir() {
                return Ok(candidate.to_path_buf());
            }
        }
    }
    let cwd = std::env::current_dir()?;
    if cwd.join("app").is_dir() {
        return Ok(cwd);
    }
    Err(eyre!(
        "cannot locate repository root, set KIOSK_ROOT to the get_kiosk checkout"
    ))
}
