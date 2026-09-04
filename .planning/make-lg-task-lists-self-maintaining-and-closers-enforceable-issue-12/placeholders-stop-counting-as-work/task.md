---
title: Placeholders stop counting as work
tier: plan
domains:
  - planning
status: ready
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

- [ ] `templates/lg/phase.md:23` — `(no tasks yet …)` becomes plain italic text, not `- [ ]`
- [ ] `templates/lg/task.md:32` — `(no atoms yet …)` likewise
- [ ] Confirm `plan-status.sh` needs no change once the lines are not checkboxes (`count_boxes` matches `^[[:space:]]*- \[[ xX]\] `)
- [ ] Re-run the reproduction: a fresh phase with two tasks must report `0/2 boxes`, not `0/5`
- [ ] Assert the "complete by ticking nothing" hole is closed: a phase with unstarted tasks must never read COMPLETE
- [ ] Check no existing plan in this repo regresses — `.planning/` holds two real plans plus the archive
- [ ] Decide whether shipped plans already carrying placeholder checkboxes need a migration note (they self-correct as tasks are added, once task 1 lands)

## Decisions Made

**One-character-class edit, largest effect.** Dropping `- [ ]` from two template lines
closes the completion hole without touching `plan-status.sh` at all — the counter already
only matches real checkboxes.

**Keep the placeholder text.** It is genuinely useful guidance for an empty phase; it just
must not be a unit of work.

## Status
**Currently ready** — independent of task 1 — different files, no shared logic.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true`.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
