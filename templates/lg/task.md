---
title: TASK_TITLE_PLACEHOLDER
tier: plan
domains:
  - planning
status: draft
last_updated: "TASK_DATE_PLACEHOLDER"
plan_kind: task
parent: PHASE_SLUG_PLACEHOLDER
depends_on: []
parallelizable: false
---

# Task: TASK_TITLE_PLACEHOLDER

**Phase**: `PHASE_SLUG_PLACEHOLDER`

## Goal
[One sentence describing the deliverable end-state for this task.]

## Atoms
[Atomic checkbox items that will be picked up by subagents. Each atom should be
something a single subagent can complete in one focused pass.

For complex atoms that need explicit subagent context, spawn a standalone atom file
via `/start-atom "Atom name" --parent TASK_SLUG_PLACEHOLDER` — these become files
under `atoms/` that subagents read via the planning MCP.

Inline checkbox vs. standalone atom file — see anti-pattern doc:
docs/atom-granularity.md.]

- [ ] (no atoms yet — add inline checkboxes here for simple atoms,
      or run `/start-atom "Atom name" --parent TASK_SLUG_PLACEHOLDER` for complex ones)

## Decisions Made
[Task-level decisions. Format: `**Decision**: rationale`.]

## Status
**Currently draft** — task has been initialized but no atoms defined.

Status enum: `draft | active | paused | done | archived`

## Dependencies
This task does not currently depend on other tasks. Edit `depends_on:` in frontmatter
to declare dependencies on other tasks within the same phase. Tasks with no
inter-dependencies should set `parallelizable: true`.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
