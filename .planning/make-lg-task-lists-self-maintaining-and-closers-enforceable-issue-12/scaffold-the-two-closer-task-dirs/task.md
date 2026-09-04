---
title: Scaffold the two closer task dirs
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: [init-scripts-maintain-their-parent-list]
parallelizable: false
---

# Task: Scaffold the two closer task dirs

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
`init-phase.sh` creates both mandatory closers as real task directories, so they are addressable artifacts like every other task instead of two lines of prose.

## Atoms

- [x] `init-phase.sh` creates `validate-success-through-comprehensive-testing/` and `documentation-pass-create-update-deprecate-docs/` from `templates/lg/task.md`
- [x] Both get `mandatory: true` and `parallelizable: false` in frontmatter
- [x] Both get seeded goals and starter atoms, not empty placeholders — the docs closer names `hewtd integrate` / `archive` / `maintain --quick` inline, matching the wording the phase template now mandates
- [x] The docs closer's atoms state the MUST: if hit-em-with-the-docs is installed, the pass goes through it
- [x] The phase's checkbox lines reference the real slugs, so the list and the directories agree from the start
- [x] Every subsequent `/start-task` lands above them (relies on task 1)
- [x] Existing phases without closer dirs must keep working — the enforcement in task 4 has to treat "no closer dirs" as legacy, not as failure
- [x] `templates/lg/task.md` gains an optional `mandatory:` field, defaulting absent

## Decisions Made

**Verified**: a phase now ships with both closer directories (`task.md` + `notes.md` +
`atoms/`), `mandatory: true`, `parallelizable: false`, 4 and 7 seeded atoms respectively.
A task created afterwards lands above both. `templates/lg/task.md` gained
`mandatory: false` as the default, flipped to `true` for closers.

**Seed real content, not empty templates.** The reason these get hand-built every time is
that an empty `task.md` is no more useful than a checkbox. The seeded atoms are what make
scaffolding worth doing.

**Legacy phases must not break.** Plans created before this change have no closer
directories; task 4's gate has to degrade to the current checkbox behavior for them.

## Status
**Currently done** — `scripts/init-phase.sh` `scaffold_closer()`, `templates/lg/task.md`, `templates/lg/phase.md`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
