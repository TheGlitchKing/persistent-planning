---
title: PHASE_TITLE_PLACEHOLDER
tier: plan
domains:
  - planning
status: draft
last_updated: "PHASE_DATE_PLACEHOLDER"
plan_kind: phase
parent: null
---

# Phase: PHASE_TITLE_PLACEHOLDER

## Goal
[One sentence describing what this phase achieves and the strategic boundary it represents.]

## Tasks
[Tasks created with `/start-task --parent PHASE_SLUG_PLACEHOLDER` will be tracked here.
Each task is a bounded deliverable. Tasks default to dependencies-first scheduling.
Tasks with no inter-dependencies can be marked `parallelizable: true` in their frontmatter
so subagent teams can pick them up concurrently.]

- [ ] (no tasks yet — run `/start-task "Task name" --parent PHASE_SLUG_PLACEHOLDER`)

## Decisions Made
[Phase-level decisions that affect multiple tasks. Format: `**Decision**: rationale`.]

## Status
**Currently draft** — phase has been initialized but no tasks defined.

Status enum: `draft | active | paused | done | archived`

When all tasks are `done`, mark this phase `done`. When archived, this directory and
its tasks/atoms move to `.planning/archive/PHASE_SLUG_PLACEHOLDER/`.

---

## Layer reference (lg mode)
- **Phase** (this file): strategic grouping of related tasks
- **Task** (`.planning/PHASE_SLUG_PLACEHOLDER/<task-slug>/task.md`): bounded deliverable
- **Atom** (`.planning/PHASE_SLUG_PLACEHOLDER/<task-slug>/atoms/<atom-slug>.md`): subagent hand-off unit
- **Notes** (`.planning/PHASE_SLUG_PLACEHOLDER/notes.md` or per-task `notes.md`): cross-cutting references
