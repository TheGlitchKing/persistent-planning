---
title: Placeholders stop counting as work
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: []
parallelizable: true
---

# Task: Placeholders stop counting as work

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
A plan can no longer read COMPLETE by ticking lines that say nothing exists, and a finished plan no longer waits on one.

## Atoms

- [x] `templates/lg/phase.md` — `(no tasks yet …)` is now italic text, not `- [ ]`
- [x] `templates/lg/task.md` — `(no atoms yet …)` likewise, both lines
- [x] `planning_insert_list_item`'s drop pattern extended to the italic form, so the placeholder still disappears on first insert
- [x] `plan-status.sh` needed no change — `count_boxes` only matches `^[[:space:]]*- \[[ xX]\] `
- [x] Reproduction from the issue now reports **0/4 boxes** where it reported 0/5
- [x] A task with no atoms contributes **zero** boxes (was 1)
- [x] Full suite still green — 74 passed, 0 failed
- [x] No migration needed for existing plans: this repo's live plans already had their placeholders removed by hand, and any that still carry one self-correct on the next `/start-task`

## Decisions Made

**The "tick nothing" hole is closed; ticking a *real* task line is still completion.**
Worth stating precisely, because the atom as originally written overreached. The defect
was that `(no tasks yet)` was a checkable unit of work — a plan could reach 100% on lines
asserting nothing existed. That is gone. A human ticking `- [ ] **Build the widget**` is a
deliberate claim that the task is done, and under the current model that legitimately
counts. The stronger guarantee — that the mandatory closers must actually be `status: done`
and not merely ticked — is task 4's job, not this one's.

**One-character-class edit, largest effect.** Dropping `- [ ]` from two template lines
closes the completion hole without touching `plan-status.sh` at all — the counter already
only matches real checkboxes.

**Keep the placeholder text.** It is genuinely useful guidance for an empty phase; it just
must not be a unit of work.

## Status
**Currently done** — `templates/lg/phase.md`, `templates/lg/task.md`, plus the drop pattern in `scripts/lib/planning.sh`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true`.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
