---
title: Lg-Mode Layered Planning Guide
tier: guide
domains:
  - planning
status: active
last_updated: 2026-05-07
version: 1.0.0
audience:
  - developers
purpose: Full guide to lg-mode (large/team) persistent-planning — phase / task / atom / notes layered model, scheduling defaults, subagent contract, and integration with semantic-memory MCP.
---

# Lg-Mode (Layered Planning)

Lg mode was introduced in **persistent-planning 3.0.0**. It complements the original sm-mode flow without replacing it — solo devs and quick spikes still get the v2 single-task experience.

## When to use lg mode

- 2+ contributors over the last 90 days (auto-detected → lg)
- Multi-week or multi-task project with strategic boundaries (phases)
- Subagent hand-off needed for parallel or sequenced work
- Wanting the plan to integrate with semantic-memory's MCP (lg plans carry HEWTD frontmatter)

If none of those apply, sm mode is faster and lighter. You can always run `/start-planning --mode lg "name"` to switch.

## The four layers

| Layer | File | Purpose |
|---|---|---|
| **Phase** | `<phase-slug>/phase.md` | Strategic grouping; multi-task boundary |
| **Task** | `<phase-slug>/<task-slug>/task.md` | Bounded deliverable; mid-level summary |
| **Atom** | `<phase-slug>/<task-slug>/atoms/<atom-slug>.md` | Subagent hand-off unit |
| **Notes** | `<phase-slug>/notes.md` or `<task-slug>/notes.md` | Cross-cutting references |

Notes are scoped to either a phase or a task (or both). Notes are NOT part of the hierarchy — they're cross-cutting context.

## Directory layout

```
.planning/
├── .meta/
│   └── workspace.json              # {mode: "lg", auto_detected: true, ...}
├── archive/
│   └── <archived-phase-slug>/      # phases moved here on status: archived
└── <phase-slug>/
    ├── phase.md                    # the phase
    ├── notes.md                    # phase-scoped notes
    └── <task-slug>/
        ├── task.md                 # the task
        ├── notes.md                # task-scoped notes
        └── atoms/
            ├── <atom-slug>.md      # sequence: 1
            └── <atom-slug>.md      # sequence: 2
```

A standalone task (without a phase) lives at `.planning/<task-slug>/` — same as sm mode but with HEWTD frontmatter and the new templates.

## Lifecycle status

Each layer has a status enum tracked in frontmatter:

- **phase.status**: `draft | active | paused | done | archived`
- **task.status**: same enum
- **atom.status**: `ready | in_progress | done | blocked`

Status transitions are explicit. Atoms additionally support **reopen** (`done → in_progress`) with a `reopened_at: <iso-timestamp>` audit field for legitimate post-completion fixes.

When a phase is marked `archived`, the entire `<phase-slug>/` directory moves to `archive/<phase-slug>/`. Atoms and tasks within move with it.

## Scheduling: dependencies-first, then parallelism

Tasks declare scheduling intent in frontmatter:

```yaml
plan_kind: task
parent: foundation
depends_on: [hewtd-schema-extension]   # this task waits for that one
parallelizable: false                  # only true if no inter-deps
```

The planning MCP's `next_task(phase)` verb (added in semantic-memory 1.0) walks the `depends_on` graph and returns the next ready task respecting the order. Tasks with `parallelizable: true` and no inter-deps can be returned in any order — perfect for subagent teams picking up work concurrently.

**Atoms within a task default to sequential** (`sequence: 1, 2, 3...`). Atom-level parallelism is a Phase 4.x conversation.

## Subagent contract

Lg-mode plans are designed to be **read by subagents via semantic-memory MCP verbs**, not by parsing markdown. The contract:

- `read_phase(slug)`, `read_task(slug)`, `read_atom(slug)`, `read_notes(scope?)`
- `list_phases(status?)`, `list_tasks(phase?, status?)`, `list_atoms(task?, status?)`
- `next_task(phase, exclude_in_progress?)` — respects depends_on + parallelizable
- `next_atom(task)` — returns the next ready atom in sequence
- `update_atom_status(slug, status)`, `update_task_status(slug, status)`, `update_phase_status(slug, status)`
- `get_planning_context(scope, slug)` — bundles parent chain + sibling status + relevant notes for one read; the subagent's primary "load my context" verb
- `append_notes(scope, slug, content)` — append-only writer for notes during execution

These verbs ship in semantic-memory 1.0 (registered conditionally on the `plans` corpus being active). When semantic-memory is absent, persistent-planning falls back to filesystem-based reads — slash commands still work; subagent comprehension degrades.

## HEWTD frontmatter

Every layer carries HEWTD-aligned frontmatter (`tier: plan`). The `version` field is intentionally omitted — HEWTD 2.2.0 makes it conditionally optional for plan-tier docs (plans use lifecycle status, not semver).

This means lg-mode plans:
- Validate against HEWTD's metadata schema
- Are searchable + filterable by HEWTD's domain / load_priority / status fields
- Get indexed by semantic-memory's `plans` corpus for free
- Get drift-detected against the codebase by semantic-memory's drift verb (when both code corpus + plans corpus are active)

## Migration from v2 (sm)

Existing `.planning/<task-slug>/{task_plan.md, notes.md}` directories continue to work without changes. They're treated as sm-mode tasks. The first time you run `/start-planning` on a project that auto-detects to lg, a `.planning/.meta/workspace.json` is written and lg-mode flow begins for new plans. Existing v2 plans aren't migrated — they coexist.

To explicitly migrate a v2 plan to lg, manually:
1. `mkdir .planning/<phase-slug>` and create `phase.md` with the high-level goal
2. Move the existing `<task-slug>/` under it
3. Convert `task_plan.md` → `task.md` (rename + add HEWTD frontmatter)

## Slash commands

| Command | Mode | Creates |
|---|---|---|
| `/start-planning "<name>"` | sm or lg (auto-detect) | sm: task; lg: phase |
| `/start-planning "<name>" --mode lg` | lg (explicit) | phase |
| `/start-planning "<name>" --mode sm` | sm (explicit) | task |
| `/start-task "<name>" --parent <phase>` | lg only | task under phase |
| `/start-atom "<name>" --parent <task>` | lg only | atom under task |

## See also

- `docs/workspace-json.md` — workspace.json schema reference
- `docs/atom-granularity.md` — when to spawn an atom file vs. inline checkbox
- `templates/lg/{phase,task,atom,notes}.md` — frontmatter shapes
- `scripts/detect-mode.sh` — mode resolution logic
- `scripts/init-{phase,task,atom}.sh` — init script implementations
