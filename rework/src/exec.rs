//! Subprocess execution with streamed output.
//!
//! Every shell command of the original installer is expressed through [`Shell`].
//! Output is streamed line by line to the UI and appended to the install log,
//! so the TUI never has to hand the terminal back to a child process.

use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use color_eyre::eyre::{Result, eyre};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::Command;
use tokio::sync::mpsc::Sender;

use crate::task::TaskEvent;

/// Installer-wide context: checkout root, asset directory and log destination.
#[derive(Clone, Debug)]
pub struct Ctx {
    pub repo_root: PathBuf,
    pub assets_dir: PathBuf,
    pub log_path: PathBuf,
}

impl Ctx {
    pub fn app(&self) -> PathBuf {
        self.repo_root.join("app")
    }

    /// Scratch directory for downloads.
    pub fn work(&self) -> PathBuf {
        self.repo_root.join("work")
    }

    /// Read a shipped asset; the UI reports the error instead of panicking.
    pub fn asset(&self, name: &str) -> Result<String> {
        crate::assets::load(&self.assets_dir, name)
    }
}

/// Quote a single argument for `/bin/sh`.
pub fn shell_quote(arg: &str) -> String {
    quote(arg)
}

/// Quote a single argument for `/bin/sh`.
fn quote(arg: &str) -> String {
    format!("'{}'", arg.replace('\'', r"'\''"))
}

fn quote_all(argv: &[&str]) -> String {
    argv.iter().map(|a| quote(a)).collect::<Vec<_>>().join(" ")
}

/// Streams command output to the UI and the log file.
pub struct Shell {
    tx: Sender<TaskEvent>,
    log: tokio::fs::File,
    abort: Arc<AtomicBool>,
    pub warnings: usize,
}

impl Shell {
    pub async fn new(ctx: &Ctx, tx: Sender<TaskEvent>, abort: Arc<AtomicBool>) -> Result<Self> {
        if let Some(parent) = ctx.log_path.parent() {
            let _ = tokio::fs::create_dir_all(parent).await;
        }
        let log = tokio::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&ctx.log_path)
            .await
            .map_err(|e| eyre!("cannot open {}: {e}", ctx.log_path.display()))?;
        Ok(Self {
            tx,
            log,
            abort,
            warnings: 0,
        })
    }

    pub fn aborted(&self) -> bool {
        self.abort.load(Ordering::Relaxed)
    }

    /// Emit one line to the UI and the log.
    pub async fn line(&mut self, text: impl Into<String>) {
        let text = text.into();
        let _ = self.tx.send(TaskEvent::Line(text.clone())).await;
        let _ = self.log.write_all(format!("{text}\n").as_bytes()).await;
    }

    async fn warn(&mut self, argv: &[&str], code: Option<i32>) {
        self.warnings += 1;
        let code = match code {
            Some(c) => format!("exit {c}"),
            None => "spawn error".to_string(),
        };
        self.line(format!(
            "! {} ({code})",
            argv.first().copied().unwrap_or("?")
        ))
        .await;
    }

    /// Run an argv command; failures are recorded as warnings, matching the
    /// original scripts which never used `set -e`.
    pub async fn run(&mut self, argv: &[&str]) -> bool {
        if self.aborted() {
            return false;
        }
        let script = format!("exec {} 2>&1", quote_all(argv));
        self.stream(&script, Some(argv)).await
    }

    /// Run a raw shell script; failures are recorded as warnings.
    pub async fn sh(&mut self, script: &str) -> bool {
        if self.aborted() {
            return false;
        }
        self.stream(script, None).await
    }

    /// Run a script but log only `label` instead of the script body.
    pub async fn sh_quiet(&mut self, script: &str, label: &str) -> bool {
        self.stream_quiet(script, label).await
    }

    /// Run a script without echoing its body; `label` is shown instead.
    async fn stream_quiet(&mut self, script: &str, label: &str) -> bool {
        if self.aborted() {
            return false;
        }
        self.line(format!("$ {label}")).await;
        self.spawn_and_wait(script, None).await
    }

    async fn stream(&mut self, script: &str, argv: Option<&[&str]>) -> bool {
        self.line(format!("$ {script}")).await;
        self.spawn_and_wait(script, argv).await
    }

    async fn spawn_and_wait(&mut self, script: &str, argv: Option<&[&str]>) -> bool {
        let mut child = match Command::new("/bin/sh")
            .arg("-c")
            .arg(script)
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()
        {
            Ok(c) => c,
            Err(e) => {
                self.line(format!("! spawn failed: {e}")).await;
                self.warnings += 1;
                return false;
            }
        };

        if let Some(stdout) = child.stdout.take() {
            let mut lines = BufReader::new(stdout).lines();
            while let Ok(Some(line)) = lines.next_line().await {
                self.line(line).await;
            }
        }

        let status = child.wait().await;
        match status {
            Ok(s) if s.success() => true,
            Ok(s) => {
                if let Some(argv) = argv {
                    self.warn(argv, s.code()).await;
                } else {
                    self.warnings += 1;
                }
                false
            }
            Err(e) => {
                self.line(format!("! wait failed: {e}")).await;
                self.warnings += 1;
                false
            }
        }
    }

    /// Run a script and return its trimmed stdout without echoing it.
    pub async fn capture(&mut self, script: &str) -> Option<String> {
        let out = Command::new("/bin/sh")
            .arg("-c")
            .arg(script)
            .stdin(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .await
            .ok()?;
        if !out.status.success() {
            return None;
        }
        let text = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if text.is_empty() { None } else { Some(text) }
    }

    /// Write a file as root through `sudo tee`, creating parent directories.
    ///
    /// Only a one-line summary reaches the log; the payload can be large and
    /// would otherwise flood the transcript.
    pub async fn write_root(&mut self, path: &str, content: &str) -> bool {
        let parent = Path::new(path)
            .parent()
            .map(|p| p.display().to_string())
            .unwrap_or_else(|| "/".to_string());
        let script = format!(
            "sudo mkdir -p {parent} && printf '%s' {} | sudo tee {path} >/dev/null",
            quote(content)
        );
        let label = format!("write {path} ({} bytes)", content.len());
        self.stream_quiet(&script, &label).await
    }

    pub async fn mkdir_root(&mut self, path: &str) -> bool {
        let script = format!("sudo mkdir -p {path}");
        let label = format!("mkdir -p {path}");
        self.stream_quiet(&script, &label).await
    }
}
