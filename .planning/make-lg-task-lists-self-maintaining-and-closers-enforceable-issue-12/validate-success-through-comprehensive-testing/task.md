---
title: Validate success through comprehensive testing
tier: plan
domains:
  - planning
status: ready
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: [init-scripts-maintain-their-parent-list, placeholders-stop-counting-as-work, scaffold-the-two-closer-task-dirs, enforce-mandatory-closers-in-plan-status]
parallelizable: false
---

# Task: Validate success through comprehensive testing

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
Every claim this phase makes is covered by a test that fails if it breaks — and the tests assert invariants after mutation, not the shape of a freshly rendered template.

## Atoms

### The invariant the current suite cannot see

- [ ] Create a phase, add three tasks, assert the two closers are **still** the last two entries — the existing assertions (`tests/run.sh:65-75, 103-112`) only ever see a pristine render
- [ ] Assert each added task appears in `phase.md` exactly once, in creation order, above the closers
- [ ] Assert the `(no tasks yet)` placeholder is gone after the first task
- [ ] Assert re-running `init-task.sh` for an existing slug does not double-insert, including under `PLANNING_FORCE=1`
- [ ] Assert insertion still lands correctly in a hand-reordered/annotated list

### Atoms

- [ ] Same coverage for `init-atom.sh` into its parent `task.md`, including the `(no atoms yet)` placeholder
- [ ] Assert `sequence:` auto-increment still works alongside the list edit

### Completion math

- [ ] A fresh phase with two tasks reports `0/2 boxes`, not `0/5`
- [ ] A phase with unstarted tasks never reads COMPLETE — the "tick nothing" hole is closed
- [ ] A phase whose real work is done is not held open by a placeholder
- [ ] A plan with an incomplete `mandatory: true` task never reads COMPLETE regardless of box count
- [ ] `--complete` and `--nudge` honour the gate
- [ ] `archive-plan.sh` refuses such a plan through its pre-flight, with no second copy of the rule

### Regression

- [ ] Legacy plans with no closer dirs and no `mandatory:` frontmatter behave exactly as before
- [ ] sm mode untouched — `init-planning.sh` output byte-identical to before this phase
- [ ] Full suite green (74 assertions at the start of this phase)

## Decisions Made

**Test after mutation, not at render.** The whole reason the ordering rule went unenforced
is that the only assertions ran against a freshly rendered template, which can never be
wrong. Every new assertion here mutates first, then checks.

**sm output must be byte-identical.** `CLAUDE.md` requires v2 behavior preserved
bit-for-bit; a diff against a pre-change render is the cheapest proof.

## Status
**Currently ready** — MANDATORY, second-to-last. Gates on all four implementation tasks.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
