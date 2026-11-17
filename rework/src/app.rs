//! Application state machine (Elm Architecture: Model, Message, Update, View).

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant};

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use ratatui::DefaultTerminal;
use tokio::sync::mpsc::{Receiver, Sender, channel};

use crate::exec::Ctx;
use crate::steps::{Field, StepKind};
use crate::task::{Answers, Plan, TaskEvent, run_plan};
use crate::ui;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Screen {
    Menu,
    Form,
    Confirm,
    Running,
    Finished,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum StepState {
    Pending,
    Running,
    Ok(usize),
    Failed(usize),
    Skipped,
}

pub enum Message {
    Up,
    Down,
    PageUp,
    PageDown,
    Top,
    Bottom,
    Toggle,
    Left,
    Right,
    Submit,
    Back,
    Char(char),
    Backspace,
    Abort,
    Quit,
    Tick,
    Task(TaskEvent),
    None,
}

pub struct App {
    pub ctx: Ctx,
    pub screen: Screen,
    pub cursor: usize,
    pub selected: [bool; 13],
    pub log: Vec<String>,
    pub scroll: u16,
    pub auto_scroll: bool,
    pub steps: Vec<StepKind>,
    pub step_states: HashMap<StepKind, StepState>,
    pub active_step: Option<StepKind>,
    pub done: Option<DoneSummary>,

    form_step: Option<StepKind>,
    form_fields: Vec<Field>,
    form_index: usize,
    form_texts: Vec<String>,
    form_choices: Vec<usize>,
    answers: HashMap<StepKind, Answers>,

    tx: Option<Sender<TaskEvent>>,
    rx: Option<Receiver<TaskEvent>>,
    events: Receiver<Event>,
    abort: Arc<AtomicBool>,
    quit: bool,

    spinner: usize,
    started_at: Option<Instant>,
}

#[derive(Clone, Copy, Debug)]
pub struct DoneSummary {
    pub ok: usize,
    pub failed: usize,
    pub aborted: bool,
    pub elapsed: Duration,
}

impl App {
    pub fn new(ctx: Ctx) -> Self {
        let events = spawn_event_thread();
        Self {
            ctx,
            screen: Screen::Menu,
            cursor: 0,
            selected: [false; 13],
            log: Vec::new(),
            scroll: 0,
            auto_scroll: true,
            steps: StepKind::ALL.to_vec(),
            step_states: HashMap::new(),
            active_step: None,
            done: None,
            form_step: None,
            form_fields: Vec::new(),
            form_index: 0,
            form_texts: Vec::new(),
            form_choices: Vec::new(),
            answers: HashMap::new(),
            tx: None,
            rx: None,
            events,
            abort: Arc::new(AtomicBool::new(false)),
            quit: false,
            spinner: 0,
            started_at: None,
        }
    }

    pub async fn run(&mut self, terminal: &mut DefaultTerminal) -> Result<()> {
        let mut ticker = tokio::time::interval(Duration::from_millis(120));
        let mut task_rx = self.rx.take();
        loop {
            if self.quit {
                break;
            }
            terminal.draw(|frame| ui::render(self, frame))?;

            enum Trigger {
                Event(Option<Event>),
                Task(Option<TaskEvent>),
                Tick,
            }

            let has_task = task_rx.is_some();
            let trigger = tokio::select! {
                maybe_event = self.events.recv() => Trigger::Event(maybe_event),
                maybe_task = async {
                    match task_rx.as_mut() {
                        Some(rx) => rx.recv().await,
                        None => std::future::pending().await,
                    }
                }, if has_task => Trigger::Task(maybe_task),
                _ = ticker.tick() => Trigger::Tick,
            };

            match trigger {
                Trigger::Event(Some(event)) => {
                    let msg = translate(event, self.screen);
                    self.update(msg);
                }
                Trigger::Event(None) => self.quit = true,
                Trigger::Task(Some(task)) => self.update(Message::Task(task)),
                Trigger::Task(None) => {
                    task_rx = None;
                    self.rx = None;
                }
                Trigger::Tick => self.update(Message::Tick),
            }

            if self.rx.is_some() && task_rx.is_none() {
                task_rx = self.rx.take();
            }
        }
        self.abort.store(true, Ordering::Relaxed);
        Ok(())
    }

    pub fn spinner_frame(&self) -> usize {
        self.spinner % 4
    }

    pub fn selected_count(&self) -> usize {
        self.selected.iter().filter(|s| **s).count()
    }

    pub fn push_log(&mut self, line: impl Into<String>) {
        let line = line.into();
        for part in line.split('\n') {
            if self.log.len() >= 4000 {
                self.log.remove(0);
                self.scroll = self.scroll.saturating_sub(1);
            }
            self.log.push(part.to_string());
        }
        if self.auto_scroll {
            self.scroll = self.log.len().saturating_sub(1) as u16;
        }
    }

    fn update(&mut self, msg: Message) {
        match msg {
            Message::Quit => self.quit = true,
            Message::Tick => self.spinner = self.spinner.wrapping_add(1),
            Message::Task(task) => self.on_task_event(task),
            Message::Back => self.go_back(),
            Message::Abort => {
                if self.screen == Screen::Running {
                    self.abort.store(true, Ordering::Relaxed);
                    self.push_log("! abort requested, finishing current command");
                }
            }
            _ => match self.screen {
                Screen::Menu => self.update_menu(msg),
                Screen::Form => self.update_form(msg),
                Screen::Confirm => self.update_confirm(msg),
                Screen::Running => self.update_running(msg),
                Screen::Finished => self.update_finished(msg),
            },
        }
    }

    fn update_menu(&mut self, msg: Message) {
        match msg {
            Message::Char('q') => self.quit = true,
            Message::Up => self.cursor = self.cursor.saturating_sub(1),
            Message::Down => {
                if self.cursor + 1 < self.steps.len() {
                    self.cursor += 1;
                }
            }
            Message::Toggle => {
                let idx = self.cursor;
                self.selected[idx] = !self.selected[idx];
            }
            Message::Submit => {
                if self.selected_count() == 0 {
                    self.push_log("select at least one component before starting");
                    return;
                }
                let first = self
                    .steps
                    .iter()
                    .copied()
                    .zip(self.selected)
                    .find(|(_, on)| *on)
                    .map(|(step, _)| step);
                match first {
                    Some(step) => self.start_form(step),
                    None => self.screen = Screen::Confirm,
                }
            }
            _ => {}
        }
    }

    fn update_form(&mut self, msg: Message) {
        match msg {
            Message::Up => self.form_index = self.form_index.saturating_sub(1),
            Message::Down => {
                if self.form_index + 1 < self.form_fields.len() {
                    self.form_index += 1;
                }
            }
            Message::Left => {
                if let Some(Field::Choose { options, .. }) = self.form_fields.get(self.form_index) {
                    let n = options.len();
                    if n > 0 {
                        let cur = self.form_choices[self.form_index];
                        self.form_choices[self.form_index] = (cur + n - 1) % n;
                    }
                }
            }
            Message::Right => {
                if let Some(Field::Choose { options, .. }) = self.form_fields.get(self.form_index) {
                    let n = options.len();
                    if n > 0 {
                        let cur = self.form_choices[self.form_index];
                        self.form_choices[self.form_index] = (cur + 1) % n;
                    }
                }
            }
            Message::Char(c) => {
                if matches!(
                    self.form_fields.get(self.form_index),
                    Some(Field::Text { .. })
                ) {
                    self.form_texts[self.form_index].push(c);
                }
            }
            Message::Backspace => {
                if matches!(
                    self.form_fields.get(self.form_index),
                    Some(Field::Text { .. })
                ) {
                    self.form_texts[self.form_index].pop();
                }
            }
            Message::Submit => {
                if self.form_index + 1 < self.form_fields.len() {
                    self.form_index += 1;
                } else if let Some(step) = self.form_step {
                    self.advance_from(step);
                } else {
                    self.commit_form();
                }
            }
            _ => {}
        }
    }

    fn update_confirm(&mut self, msg: Message) {
        if let Message::Submit = msg {
            self.start_run();
        }
    }

    fn update_running(&mut self, msg: Message) {
        match msg {
            Message::Up => {
                self.auto_scroll = false;
                self.scroll = self.scroll.saturating_sub(1);
            }
            Message::Down => {
                let max = self.log.len().saturating_sub(1) as u16;
                self.scroll = (self.scroll + 1).min(max);
                if self.scroll >= max {
                    self.auto_scroll = true;
                }
            }
            Message::PageUp => {
                self.auto_scroll = false;
                self.scroll = self.scroll.saturating_sub(10);
            }
            Message::PageDown => {
                let max = self.log.len().saturating_sub(1) as u16;
                self.scroll = (self.scroll + 10).min(max);
            }
            Message::Top => {
                self.auto_scroll = false;
                self.scroll = 0;
            }
            Message::Bottom => {
                self.auto_scroll = true;
                self.scroll = self.log.len().saturating_sub(1) as u16;
            }
            _ => {}
        }
    }

    fn update_finished(&mut self, msg: Message) {
        match msg {
            Message::Up => {
                self.auto_scroll = false;
                self.scroll = self.scroll.saturating_sub(1);
            }
            Message::Down => {
                let max = self.log.len().saturating_sub(1) as u16;
                self.scroll = (self.scroll + 1).min(max);
            }
            Message::PageUp => {
                self.auto_scroll = false;
                self.scroll = self.scroll.saturating_sub(10);
            }
            Message::PageDown => {
                let max = self.log.len().saturating_sub(1) as u16;
                self.scroll = (self.scroll + 10).min(max);
            }
            Message::Top => {
                self.auto_scroll = false;
                self.scroll = 0;
            }
            Message::Bottom => self.auto_scroll = true,
            _ => {}
        }
    }

    fn go_back(&mut self) {
        match self.screen {
            Screen::Finished => {
                self.screen = Screen::Menu;
                self.done = None;
                self.active_step = None;
            }
            Screen::Form => {
                if let Some(step) = self.form_step {
                    self.commit_form();
                    if let Some(prev) = self.prev_step_with_fields(step) {
                        self.start_form(prev);
                    } else {
                        self.screen = Screen::Menu;
                        self.form_step = None;
                    }
                } else {
                    self.screen = Screen::Menu;
                }
            }
            Screen::Confirm => self.screen = Screen::Menu,
            _ => {}
        }
    }

    fn start_form(&mut self, step: StepKind) {
        let fields = step.fields();
        if fields.is_empty() {
            self.advance_from(step);
            return;
        }
        let stored = self.answers.get(&step).cloned().unwrap_or_default();
        self.form_fields = fields;
        self.form_index = 0;
        self.form_texts = (0..self.form_fields.len())
            .map(|i| stored.text(i).to_string())
            .collect();
        self.form_choices = (0..self.form_fields.len())
            .map(|i| stored.choice(i))
            .collect();
        self.form_step = Some(step);
        self.screen = Screen::Form;
    }

    fn commit_form(&mut self) {
        if let Some(step) = self.form_step {
            self.answers.insert(
                step,
                Answers {
                    texts: self.form_texts.clone(),
                    choices: self.form_choices.clone(),
                },
            );
        }
    }

    fn advance_from(&mut self, step: StepKind) {
        // Only commit when the answers on screen belong to `step`; an empty
        // step is skipped straight through and must not overwrite the
        // previous step's answers.
        if self.form_step == Some(step) {
            self.commit_form();
        }
        match self.next_step_with_fields(step) {
            Some(next) => self.start_form(next),
            None => {
                self.form_step = None;
                self.screen = Screen::Confirm;
                self.cursor = 0;
            }
        }
    }

    fn next_step_with_fields(&self, step: StepKind) -> Option<StepKind> {
        let mut seen = false;
        for (candidate, on) in self.steps.iter().copied().zip(self.selected) {
            if !on {
                continue;
            }
            if seen && !candidate.fields().is_empty() {
                return Some(candidate);
            }
            if candidate == step {
                seen = true;
            }
        }
        None
    }

    fn prev_step_with_fields(&self, step: StepKind) -> Option<StepKind> {
        let mut previous = None;
        for (candidate, on) in self.steps.iter().copied().zip(self.selected) {
            if !on {
                continue;
            }
            if candidate == step {
                return previous;
            }
            if !candidate.fields().is_empty() {
                previous = Some(candidate);
            }
        }
        None
    }

    fn start_run(&mut self) {
        let steps: Vec<StepKind> = self
            .steps
            .iter()
            .copied()
            .zip(self.selected)
            .filter(|(_, on)| *on)
            .map(|(step, _)| step)
            .collect();
        if steps.is_empty() {
            return;
        }

        self.commit_form();
        let plan = Plan {
            steps: steps.clone(),
            answers: self.answers.clone(),
        };

        self.step_states = steps.iter().map(|s| (*s, StepState::Pending)).collect();
        self.active_step = None;
        self.screen = Screen::Running;
        self.log.clear();
        self.scroll = 0;
        self.auto_scroll = true;
        self.abort.store(false, Ordering::Relaxed);
        self.started_at = Some(Instant::now());
        self.done = None;

        let (tx, rx) = channel::<TaskEvent>(256);
        self.tx = Some(tx.clone());
        self.rx = Some(rx);

        let ctx = self.ctx.clone();
        let abort = self.abort.clone();
        tokio::spawn(async move {
            run_plan(ctx, plan, tx, abort).await;
        });
        self.push_log(format!("starting {} step(s)", steps.len()));
    }

    fn on_task_event(&mut self, task: TaskEvent) {
        match task {
            TaskEvent::StepStarted { step } => {
                self.active_step = Some(step);
                self.step_states.insert(step, StepState::Running);
                self.push_log(format!("== {} ==", step.title()));
            }
            TaskEvent::Line(line) => self.push_log(line),
            TaskEvent::StepFinished {
                step,
                warnings,
                aborted,
            } => {
                let state = if aborted {
                    StepState::Skipped
                } else if warnings == 0 {
                    StepState::Ok(0)
                } else {
                    StepState::Failed(warnings)
                };
                self.step_states.insert(step, state);
                self.active_step = None;
            }
            TaskEvent::AllFinished => {
                let ok = self
                    .step_states
                    .values()
                    .filter(|s| matches!(s, StepState::Ok(_)))
                    .count();
                let failed = self
                    .step_states
                    .values()
                    .filter(|s| matches!(s, StepState::Failed(_)))
                    .count();
                let aborted = self.abort.load(Ordering::Relaxed);
                let elapsed = self.started_at.map(|t| t.elapsed()).unwrap_or_default();
                self.done = Some(DoneSummary {
                    ok,
                    failed,
                    aborted,
                    elapsed,
                });
                self.screen = Screen::Finished;
                self.push_log(format!(
                    "finished: {ok} ok, {failed} with warnings{}",
                    if aborted { ", aborted" } else { "" }
                ));
            }
            TaskEvent::Failed(err) => {
                self.push_log(format!("! runner failed: {err}"));
                self.done = Some(DoneSummary {
                    ok: 0,
                    failed: 1,
                    aborted: true,
                    elapsed: self.started_at.map(|t| t.elapsed()).unwrap_or_default(),
                });
                self.screen = Screen::Finished;
            }
        }
    }

    pub fn running_elapsed(&self) -> Option<Duration> {
        self.started_at.map(|t| t.elapsed())
    }

    pub fn form_state(&self) -> FormView<'_> {
        FormView {
            step: self.form_step,
            fields: &self.form_fields,
            index: self.form_index,
            texts: &self.form_texts,
            choices: &self.form_choices,
        }
    }

    pub fn answers_for(&self, step: StepKind) -> Answers {
        self.answers.get(&step).cloned().unwrap_or_default()
    }

    pub fn selected_steps(&self) -> Vec<StepKind> {
        self.steps
            .iter()
            .copied()
            .zip(self.selected)
            .filter(|(_, on)| *on)
            .map(|(step, _)| step)
            .collect()
    }
}

pub struct FormView<'a> {
    pub step: Option<StepKind>,
    pub fields: &'a [Field],
    pub index: usize,
    pub texts: &'a [String],
    pub choices: &'a [usize],
}

impl FormView<'_> {
    pub fn value(&self, i: usize) -> String {
        match self.fields.get(i) {
            Some(Field::Text { .. }) => self.texts.get(i).cloned().unwrap_or_default(),
            Some(Field::Choose { options, .. }) => {
                let idx = self.choices.get(i).copied().unwrap_or(0);
                options.get(idx).copied().unwrap_or("-").to_string()
            }
            None => String::new(),
        }
    }
}

fn spawn_event_thread() -> Receiver<Event> {
    let (tx, rx) = channel::<Event>(64);
    std::thread::spawn(move || {
        loop {
            match crossterm::event::poll(Duration::from_millis(250)) {
                Ok(true) => match crossterm::event::read() {
                    Ok(event) => {
                        if tx.blocking_send(event).is_err() {
                            break;
                        }
                    }
                    Err(_) => break,
                },
                Ok(false) => continue,
                Err(_) => break,
            }
        }
    });
    rx
}

fn translate(event: Event, screen: Screen) -> Message {
    let Event::Key(key) = event else {
        return Message::None;
    };
    if key.kind != KeyEventKind::Press {
        return Message::None;
    }
    handle_key(key, screen)
}

fn is_ctrl_c(key: &KeyEvent) -> bool {
    key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c')
}

fn handle_key(key: KeyEvent, screen: Screen) -> Message {
    if is_ctrl_c(&key) {
        return match screen {
            Screen::Running => Message::Abort,
            _ => Message::Quit,
        };
    }

    match key.code {
        KeyCode::Esc => Message::Back,
        KeyCode::Enter => Message::Submit,
        KeyCode::Up => Message::Up,
        KeyCode::Down => Message::Down,
        KeyCode::PageUp => Message::PageUp,
        KeyCode::PageDown => Message::PageDown,
        KeyCode::Home => Message::Top,
        KeyCode::End => Message::Bottom,
        KeyCode::Left => Message::Left,
        KeyCode::Right => Message::Right,
        KeyCode::Tab => Message::Right,
        KeyCode::Backspace => Message::Backspace,
        KeyCode::Char(' ') => match screen {
            Screen::Form => Message::Char(' '),
            _ => Message::Toggle,
        },
        KeyCode::Char('q') if screen == Screen::Finished => Message::Quit,
        KeyCode::Char(c) => Message::Char(c),
        _ => Message::None,
    }
}
