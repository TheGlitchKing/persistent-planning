---
title: Enforce mandatory closers in plan-status
tier: plan
domains:
  - planning
status: ready
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

- [ ] `plan-status.sh` reads `mandatory: true` from task frontmatter under each plan
- [ ] A plan with any incomplete mandatory task reads `in progress` (or a distinct verdict), never COMPLETE — regardless of box count
- [ ] Legacy plans with no `mandatory:` tasks keep exactly today's behavior — this must not retroactively block existing plans
- [ ] `--complete` and `--nudge` machine outputs respect the same gate; they are what the hook and `archive-plan.sh` consume
- [ ] `archive-plan.sh` inherits the gate through its pre-flight — verify, do not duplicate the rule (`CLAUDE.md`: one implementation of "is this plan done?")
- [ ] Verify the SessionStart nudge does not start firing on plans it should not
- [ ] Keep the single-implementation rule intact: no second copy of the completion logic anywhere

## Decisions Made

**One implementation of completion, still.** `CLAUDE.md` is explicit that
`plan-status.sh` is the only place that answers "is this plan done?" — the gate goes there
and everything else keeps shelling out to it.

**Additive for legacy plans.** Absent `mandatory:` means absent enforcement. A change that
retroactively marks existing finished plans incomplete would be worse than the bug.

## Status
**Currently ready** — the piece that turns the rule from prose into a guarantee.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
