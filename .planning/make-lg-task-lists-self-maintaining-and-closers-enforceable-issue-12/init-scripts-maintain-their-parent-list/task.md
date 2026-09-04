---
title: Init scripts maintain their parent list
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: []
parallelizable: false
---

# Task: Init scripts maintain their parent list

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
Creating a task writes it into its phase's list, and creating an atom writes it into its task's list — above the mandatory closers, with the placeholder removed on first use.

## Atoms

- [x] Add a shared insert helper to `scripts/lib/planning.sh` — both `init-task.sh` and `init-atom.sh` need the same "insert a checkbox line into a markdown list, above any MANDATORY entries" primitive
- [x] `init-task.sh`: append the new task's checkbox line to `phase.md`'s `## Tasks` list, positioned **above** the first line marked MANDATORY
- [x] `init-task.sh`: drop the `(no tasks yet — run …)` placeholder line when inserting the first real task
- [x] `init-atom.sh`: same treatment into the parent `task.md`'s `## Atoms` list (no MANDATORY entries there, so plain append — but reuse the helper)
- [x] `init-atom.sh`: drop the `(no atoms yet — …)` placeholder on first insert
- [x] Idempotent: re-running with an existing slug must not double-insert. `PLANNING_FORCE=1` overwrites artifacts today; the list edit has to stay correct under it
- [x] Insertion must survive a hand-edited list — match on the MANDATORY marker, not on a line number
- [x] Leave the line format identical to what a human writes today, so existing plans stay consistent

## Decisions Made

**Implemented as `planning_insert_list_item <file> <section> <line>`** in
`scripts/lib/planning.sh`. Section-scoped (heading .. next `## `), so it cannot wander
into another list. Verified end to end: two tasks land above both closers in creation
order, two atoms land in their task, both placeholders vanish on first insert, and a
repeat insert is a no-op.

**Match on the MANDATORY marker, never on line numbers.** The list is a human-editable
surface; anchoring to position would break the first time someone reorders or annotates it.

**Reuse one helper across both scripts.** `init-task.sh` and `init-atom.sh` already both
source `scripts/lib/planning.sh`; a second copy of the insert logic is exactly the kind of
drift this phase exists to remove.

## Status
**Currently done** — `scripts/lib/planning.sh`, `scripts/init-task.sh`, `scripts/init-atom.sh`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true`.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
