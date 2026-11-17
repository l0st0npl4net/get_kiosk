//! Rendering: header, menu, form, confirmation, run log and summary.

use crate::app::{App, Screen, StepState};
use crate::steps::Field;
use ratatui::Frame;
use ratatui::layout::{Constraint, Layout, Rect};
use ratatui::style::{Style, Stylize};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{
    Block, Borders, Clear, List, ListItem, Paragraph, Scrollbar, ScrollbarOrientation,
    ScrollbarState, Wrap,
};

fn status_symbol(state: Option<StepState>, spinner: usize) -> Span<'static> {
    const FRAMES: [&str; 4] = ["|", "/", "-", "\\"];
    match state {
        Some(StepState::Running) => Span::raw(format!(" {} ", FRAMES[spinner % 4])).cyan(),
        Some(StepState::Ok(_)) => Span::raw(" ok ").green(),
        Some(StepState::Failed(n)) => Span::raw(format!(" !{n} ")).yellow(),
        Some(StepState::Skipped) => Span::raw(" -- ").dim(),
        _ => Span::raw("    "),
    }
}

pub fn render(app: &mut App, frame: &mut Frame) {
    let area = frame.area();
    let [header, body, footer] = Layout::vertical([
        Constraint::Length(3),
        Constraint::Fill(1),
        Constraint::Length(2),
    ])
    .areas(area);

    render_header(app, frame, header);
    match app.screen {
        Screen::Menu => render_menu(app, frame, body),
        Screen::Form => render_form(app, frame, body),
        Screen::Confirm => render_confirm(app, frame, body),
        Screen::Running | Screen::Finished => render_run(app, frame, body),
    }
    render_footer(app, frame, footer);
}

fn render_header(app: &App, frame: &mut Frame, area: Rect) {
    let host_line = Line::from(vec![
        " GET-KIOSK ".bold().on_cyan().black(),
        " installer ".dim(),
        format!(" {} ", app.steps.len()).cyan(),
        " components ".dim(),
    ]);
    let block = Block::bordered()
        .title(Line::from(" Внедрение: Установщик Киоска ").bold())
        .title_bottom(Line::from(" ratatui rewrite ").dim());
    let inner = block.inner(area);
    frame.render_widget(block, area);
    frame.render_widget(Paragraph::new(host_line), inner);
}

fn render_menu(app: &mut App, frame: &mut Frame, area: Rect) {
    let [list_area, detail_area] =
        Layout::vertical([Constraint::Fill(3), Constraint::Length(6)]).areas(area);

    let block = Block::bordered().title(" Components ".bold());
    let items: Vec<ListItem> = app
        .steps
        .iter()
        .copied()
        .enumerate()
        .map(|(index, step)| {
            let checked = app.selected[index];
            let marker = if checked { "[x]" } else { "[ ]" };
            let state = app.step_states.get(&step).copied();
            let badge = status_symbol(state, app.spinner_frame());
            let style = if index == app.cursor {
                Style::new().on_dark_gray()
            } else {
                Style::new()
            };
            let line = Line::from(vec![
                Span::raw(if checked { " x " } else { "   " }),
                Span::raw(format!("{marker} ")).cyan(),
                Span::raw(format!("{:<18}", step.title())).style(if checked {
                    Style::new().bold()
                } else {
                    Style::new()
                }),
                badge,
            ]);
            ListItem::new(line).style(style)
        })
        .collect();

    let list = List::new(items).block(block).highlight_symbol("> ");
    let mut state = ratatui::widgets::ListState::default();
    state.select(Some(app.cursor));
    frame.render_stateful_widget(list, list_area, &mut state);

    let current = app.steps.get(app.cursor).copied();
    let detail_block = Block::bordered().title(" Detail ".bold());

    let mut lines: Vec<Line> = Vec::new();
    if let Some(step) = current {
        lines.push(Line::from(step.title().bold().cyan()));
        lines.push(Line::from(step.summary().dim()));
        let fields = step.fields();
        if fields.is_empty() {
            lines.push(Line::from("no input required".dim()));
        } else {
            let names: Vec<&str> = fields
                .iter()
                .map(|f| match f {
                    Field::Text { label, .. } => *label,
                    Field::Choose { label, .. } => *label,
                })
                .collect();
            lines.push(Line::from(vec![" needs: ".dim(), names.join(", ").into()]));
        }
    } else {
        lines.push(Line::from("no component selected".dim()));
    }
    lines.push(Line::from(""));
    lines.push(Line::from(format!(
        " selected: {} of {}",
        app.selected_count(),
        app.steps.len()
    )));
    frame.render_widget(
        Paragraph::new(Text::from(lines))
            .wrap(Wrap { trim: true })
            .block(detail_block),
        detail_area,
    );
}

fn render_form(app: &mut App, frame: &mut Frame, area: Rect) {
    let view = app.form_state();
    let title = view
        .step
        .map(|s| format!(" {} - parameters ", s.title()))
        .unwrap_or_else(|| " Parameters ".to_string());
    let block = Block::bordered().title(title.bold());
    let inner = block.inner(area);
    frame.render_widget(block, area);

    let rows: Vec<Line> = view
        .fields
        .iter()
        .enumerate()
        .map(|(i, field)| {
            let focused = i == view.index;
            let value = view.value(i);
            let label = match field {
                Field::Text { label, .. } => *label,
                Field::Choose { label, .. } => *label,
            };
            let hint = match field {
                Field::Text { hint, .. } => format!(" ({hint})"),
                Field::Choose { options, .. } => {
                    format!(" [{}/{}]", view.choices[i] + 1, options.len())
                }
            };
            let base = if focused {
                Style::new().on_dark_gray()
            } else {
                Style::new()
            };
            Line::from(vec![
                Span::raw(if focused { "> " } else { "  " }).style(base),
                Span::raw(format!("{label}: ")).style(base).bold(),
                Span::raw(value).style(if focused { base.cyan() } else { base }),
                Span::raw(hint).dim().style(base),
            ])
        })
        .collect();

    let help = Line::from(vec![
        " Enter ".bold().cyan(),
        "next / save  ".dim(),
        " arrows ".bold().cyan(),
        "move / change  ".dim(),
        " Esc ".bold().cyan(),
        "back ".dim(),
    ]);

    let [fields_area, help_area] =
        Layout::vertical([Constraint::Fill(1), Constraint::Length(2)]).areas(inner);
    frame.render_widget(Paragraph::new(rows).wrap(Wrap { trim: false }), fields_area);
    frame.render_widget(Paragraph::new(help), help_area);
}

fn render_confirm(app: &mut App, frame: &mut Frame, area: Rect) {
    let block = Block::bordered().title(" Review and run ".bold());
    let inner = block.inner(area);
    frame.render_widget(block, area);

    let steps = app.selected_steps();
    let mut lines: Vec<Line> = Vec::new();
    lines.push(Line::from("The installer runs these steps in order:".dim()));
    lines.push(Line::from(""));

    for (pos, step) in steps.iter().enumerate() {
        let answers = app.answers_for(*step);
        lines.push(Line::from(vec![
            format!(" {:>2}. ", pos + 1).dim(),
            step.title().bold(),
            format!("  {}", step.summary()).dim(),
        ]));
        let fields = step.fields();
        for (i, field) in fields.iter().enumerate() {
            let value = match field {
                Field::Text { .. } => {
                    if answers.text(i).is_empty() {
                        "<empty>".to_string()
                    } else {
                        answers.text(i).to_string()
                    }
                }
                Field::Choose { options, .. } => {
                    let idx = answers.choice(i);
                    options.get(idx).copied().unwrap_or("-").to_string()
                }
            };
            let label = match field {
                Field::Text { label, .. } => *label,
                Field::Choose { label, .. } => *label,
            };
            lines.push(Line::from(vec![
                "        ".dim(),
                format!("{label}: ").dim(),
                value.cyan(),
            ]));
        }
    }

    lines.push(Line::from(""));
    lines.push(Line::from(vec![
        " requires sudo ".bold().yellow(),
        " every step is executed silently in the background".dim(),
    ]));

    frame.render_widget(Paragraph::new(lines).wrap(Wrap { trim: true }), inner);
}

fn render_run(app: &mut App, frame: &mut Frame, area: Rect) {
    let [side, main] =
        Layout::horizontal([Constraint::Length(30), Constraint::Fill(1)]).areas(area);

    let steps_block = Block::bordered().title(" Plan ".bold());
    let items: Vec<ListItem> = app
        .selected_steps()
        .iter()
        .copied()
        .map(|step| {
            let badge = status_symbol(app.step_states.get(&step).copied(), app.spinner_frame());
            let style = if app.active_step == Some(step) {
                Style::new().bold()
            } else {
                Style::new()
            };
            ListItem::new(Line::from(vec![
                Span::raw(step.title()).style(style),
                badge,
            ]))
        })
        .collect();
    frame.render_widget(List::new(items).block(steps_block), side);

    let title = match app.screen {
        Screen::Finished => " Done ".to_string(),
        _ => {
            let active = app
                .active_step
                .map(|s| s.title().to_string())
                .unwrap_or_else(|| "waiting".to_string());
            let elapsed = app
                .running_elapsed()
                .map(|d| d.as_secs())
                .unwrap_or_default();
            format!(" Log - {active} ({elapsed}s) ")
        }
    };
    let log_block = Block::bordered().title(title.bold());
    let inner = log_block.inner(main);
    frame.render_widget(log_block, main);

    let visible = inner.height as usize;
    let total = app.log.len();
    let max_start = total.saturating_sub(visible);
    let start = if app.auto_scroll {
        max_start
    } else {
        (app.scroll as usize).min(max_start)
    };

    if total == 0 {
        let hint = Line::from(vec![
            " waiting for output ".dim(),
            " Esc ".bold().cyan(),
            " back ".dim(),
        ]);
        frame.render_widget(Paragraph::new(hint), inner);
        return;
    }

    let text: Vec<Line> = app
        .log
        .iter()
        .skip(start)
        .take(visible)
        .map(|line| style_log_line(line))
        .collect();
    frame.render_widget(Paragraph::new(text), inner);

    if total > visible {
        let mut sb = ScrollbarState::new(max_start + 1).position(start);
        frame.render_stateful_widget(
            Scrollbar::new(ScrollbarOrientation::VerticalRight)
                .begin_symbol(None)
                .end_symbol(None),
            inner,
            &mut sb,
        );
    }

    if app.screen == Screen::Finished {
        render_summary(app, frame, area);
    }
}

fn render_summary(app: &mut App, frame: &mut Frame, area: Rect) {
    let Some(done) = app.done else { return };
    let popup = centered(area, 56, 11);
    frame.render_widget(Clear, popup);
    let block = Block::bordered()
        .title(" Result ".bold())
        .border_style(Style::new().cyan());
    let inner = block.inner(popup);
    frame.render_widget(block, popup);

    let verdict = if done.aborted {
        "aborted".yellow().bold()
    } else if done.failed > 0 {
        "completed with warnings".yellow().bold()
    } else {
        "completed".green().bold()
    };

    let lines = vec![
        Line::from(vec![" result: ".dim(), verdict]),
        Line::from(vec![
            " steps ok: ".dim(),
            format!("{}", done.ok).green(),
            "  with warnings: ".dim(),
            format!("{}", done.failed).yellow(),
        ]),
        Line::from(vec![
            " elapsed: ".dim(),
            format_duration(done.elapsed).cyan(),
        ]),
        Line::from(vec![
            " log: ".dim(),
            app.ctx.log_path.display().to_string().cyan(),
        ]),
        Line::from(""),
        Line::from(vec![
            " q ".bold().cyan(),
            "quit  ".dim(),
            " Esc ".bold().cyan(),
            "back to menu ".dim(),
        ]),
    ];
    frame.render_widget(Paragraph::new(lines).wrap(Wrap { trim: true }), inner);
}

fn style_log_line(line: &str) -> Line<'static> {
    let text = line.to_string();
    if text.starts_with('!') {
        Line::from(text).yellow()
    } else if text.starts_with("$ ") {
        Line::from(text).dim()
    } else if text.starts_with("==") {
        Line::from(text).bold().cyan()
    } else if text.contains("complete!") || text.starts_with("Signing key OK") {
        Line::from(text).green()
    } else {
        Line::from(text)
    }
}

fn render_footer(app: &App, frame: &mut Frame, area: Rect) {
    let block = Block::default().borders(Borders::TOP);
    let inner = block.inner(area);
    frame.render_widget(block, area);

    let hints: Vec<Span> = match app.screen {
        Screen::Menu => vec![
            " ↑↓ ".bold().cyan(),
            "move ".dim(),
            " Space ".bold().cyan(),
            "toggle ".dim(),
            " Enter ".bold().cyan(),
            "continue ".dim(),
            " q ".bold().cyan(),
            "quit ".dim(),
        ],
        Screen::Form => vec![
            " ↑↓ ".bold().cyan(),
            "field ".dim(),
            " ←→ ".bold().cyan(),
            "value ".dim(),
            " Enter ".bold().cyan(),
            "next ".dim(),
            " Esc ".bold().cyan(),
            "back ".dim(),
        ],
        Screen::Confirm => vec![
            " Enter ".bold().cyan(),
            "run installer ".dim(),
            " Esc ".bold().cyan(),
            "back ".dim(),
        ],
        Screen::Running => vec![
            " ↑↓ ".bold().cyan(),
            "scroll ".dim(),
            " PgUp/PgDn ".bold().cyan(),
            "page ".dim(),
            " Ctrl-C ".bold().cyan(),
            "abort ".dim(),
        ],
        Screen::Finished => vec![
            " ↑↓ ".bold().cyan(),
            "scroll ".dim(),
            " q ".bold().cyan(),
            "quit ".dim(),
            " Esc ".bold().cyan(),
            "back ".dim(),
        ],
    };

    let counter = format!("{} / {}", app.cursor.saturating_add(1), app.steps.len());

    let mut spans: Vec<Span> = Vec::with_capacity(hints.len() + 3);
    spans.push(Span::raw(" "));
    spans.extend(hints);
    spans.push(Span::raw("   "));
    spans.push(Span::raw(counter).dim());

    frame.render_widget(Paragraph::new(Line::from(spans)), inner);
}

fn centered(area: Rect, percent_x: u16, height: u16) -> Rect {
    let [_, middle, _] = Layout::vertical([
        Constraint::Fill(1),
        Constraint::Length(height.min(area.height)),
        Constraint::Fill(1),
    ])
    .areas(area);
    let [_, center, _] = Layout::horizontal([
        Constraint::Fill(1),
        Constraint::Percentage(percent_x),
        Constraint::Fill(1),
    ])
    .areas(middle);
    center
}

pub fn format_duration(d: std::time::Duration) -> String {
    let secs = d.as_secs();
    if secs < 60 {
        format!("{secs}s")
    } else {
        format!("{}m {:02}s", secs / 60, secs % 60)
    }
}
