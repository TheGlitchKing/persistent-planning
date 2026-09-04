---
title: Enforce mandatory closers in plan-status
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: [scaffold-the-two-closer-task-dirs]
parallelizable: false
---

# Task: Enforce mandatory closers in plan-status

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
`plan-status.sh` refuses to call a phase COMPLETE while a `mandatory: true` task is unfinished, making the stated gate real instead of advisory.

## Atoms

- [x] `plan-status.sh` reads `mandatory: true` from task frontmatter under each plan
- [x] A plan with any incomplete mandatory task reads `in progress` (or a distinct verdict), never COMPLETE — regardless of box count
- [x] Legacy plans with no `mandatory:` tasks keep exactly today's behavior — this must not retroactively block existing plans
- [x] `--complete` and `--nudge` machine outputs respect the same gate; they are what the hook and `archive-plan.sh` consume
- [x] `archive-plan.sh` inherits the gate through its pre-flight — verify, do not duplicate the rule (`CLAUDE.md`: one implementation of "is this plan done?")
- [x] Verify the SessionStart nudge does not start firing on plans it should not
- [x] Keep the single-implementation rule intact: no second copy of the completion logic anywhere

## Decisions Made

**Verified**: a phase with every box ticked but closers still `status: draft` reads
`in progress  13/13 boxes`; `archive-plan.sh` refuses it and points at `--force`; marking
both closers `status: done` flips it to `COMPLETE` and offers the archive command. The
three live plans in this repo, none of which carry `mandatory:` frontmatter, report
exactly what they did before.

**One implementation of completion, still.** `CLAUDE.md` is explicit that
`plan-status.sh` is the only place that answers "is this plan done?" — the gate goes there
and everything else keeps shelling out to it.

**Additive for legacy plans.** Absent `mandatory:` means absent enforcement. A change that
retroactively marks existing finished plans incomplete would be worse than the bug.

## Status
**Currently done** — `scripts/plan-status.sh` `unfinished_mandatory()`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
