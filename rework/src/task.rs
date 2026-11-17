//! Background execution of the selected install plan.

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use tokio::sync::mpsc::Sender;

use crate::exec::{Ctx, Shell};
use crate::install;
use crate::steps::StepKind;

/// Answers collected in the form screen for one step.
#[derive(Clone, Debug, Default)]
pub struct Answers {
    pub texts: Vec<String>,
    pub choices: Vec<usize>,
}

impl Answers {
    pub fn text(&self, index: usize) -> &str {
        self.texts
            .get(index)
            .map(String::as_str)
            .unwrap_or_default()
    }

    pub fn choice(&self, index: usize) -> usize {
        self.choices.get(index).copied().unwrap_or(0)
    }
}

/// Selected steps in menu order, with their answers.
#[derive(Clone, Debug, Default)]
pub struct Plan {
    pub steps: Vec<StepKind>,
    pub answers: HashMap<StepKind, Answers>,
}

impl Plan {
    pub fn answers(&self, step: StepKind) -> Answers {
        self.answers.get(&step).cloned().unwrap_or_default()
    }
}

#[derive(Debug)]
pub enum TaskEvent {
    StepStarted {
        step: StepKind,
    },
    Line(String),
    StepFinished {
        step: StepKind,
        warnings: usize,
        aborted: bool,
    },
    AllFinished,
    Failed(String),
}

/// Run every step of the plan in order.
pub async fn run_plan(ctx: Ctx, plan: Plan, tx: Sender<TaskEvent>, abort: Arc<AtomicBool>) {
    // Start every run with a fresh log, like the shell installer did.
    let _ = tokio::fs::write(&ctx.log_path, "Get Kios Installation Logs\n").await;

    let total = plan.steps.len();
    for (index, step) in plan.steps.iter().copied().enumerate() {
        if tx.send(TaskEvent::StepStarted { step }).await.is_err() {
            return;
        }
        let mut shell = match Shell::new(&ctx, tx.clone(), abort.clone()).await {
            Ok(s) => s,
            Err(e) => {
                let _ = tx.send(TaskEvent::Failed(e.to_string())).await;
                return;
            }
        };

        install::run(&ctx, &mut shell, step, &plan.answers(step)).await;

        let warnings = shell.warnings;
        let aborted = shell.aborted();
        if tx
            .send(TaskEvent::StepFinished {
                step,
                warnings,
                aborted,
            })
            .await
            .is_err()
        {
            return;
        }
        if aborted {
            break;
        }
        if index + 1 < total {
            continue;
        }
    }
    let _ = tx.send(TaskEvent::AllFinished).await;
}
