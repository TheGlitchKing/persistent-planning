---
name: start-atom
description: "Add an atom (subagent hand-off unit) under an existing task in lg-mode persistent-planning. Creates .planning/<phase>/<task>/atoms/<atom-slug>.md with auto-incremented sequence. Requires --parent <task-slug>. Lg mode only."
---

# /start-atom

Add an atom — the smallest unit of planning, designed for subagent hand-off — under an existing task. **Lg mode only.**

---

## Usage

```
/start-atom "Atom name" --parent <task-slug>
```

## Examples

```
/start-atom "Update zod schema" --parent hewtd-schema-extension
/start-atom "Add plan-tier tests" --parent hewtd-schema-extension
/start-atom "Bump to 2.2.0" --parent hewtd-schema-extension
```

---

## What To Do

When the user runs `/start-atom "<name>" --parent <task-slug>`:

1. Run the init script:
```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/../scripts"
bash "${SCRIPT_DIR}/init-atom.sh" "<name>" --parent "<task-slug>"
```

The script auto-resolves which phase contains the task (no need to specify the phase). It auto-assigns the next sequence number based on existing atoms in the same task's `atoms/` directory.

If the script isn't found at that path, try:
```bash
bash scripts/init-atom.sh "<name>" --parent "<task-slug>"
bash ~/.claude/skills/persistent-planning/scripts/init-atom.sh "<name>" --parent "<task-slug>"
```

2. After completion, remind the user:
   - Edit `.planning/<phase>/<task>/atoms/<atom-slug>.md` to define:
     - `## What to do` — the atomic action
     - `## Inputs` — files / state the atom depends on
     - `## Expected outputs` — files / commands / state changes
     - `## Acceptance criteria` — how to verify completion
   - The atom starts with `status: ready`. A subagent will claim it (status → `in_progress`) and complete it (status → `done`).

---

## What It Creates

```
.planning/<phase-slug>/<task-slug>/atoms/
└── <atom-slug>.md   # HEWTD-frontmattered atom (parent: <task-slug>, sequence: N)
```

The atom file includes the structured sections needed for subagent comprehension. It's the contract a subagent reads to know exactly what to do.

## Atoms vs. inline checkboxes

Not every step needs a standalone atom file. The rule of thumb:

- **Inline checkbox in `task.md`**: simple, self-contained step that doesn't need its own context file. The user (or the active agent) handles it directly.
- **Standalone atom file via `/start-atom`**: a step that will be **handed off to a subagent**. Atoms get their own files because subagents need explicit inputs / outputs / acceptance criteria they can read structured rather than parse from prose.

See `docs/atom-granularity.md` for full anti-pattern guidance with examples.

## Sequence semantics

Atoms within a task default to **sequential** processing. The `sequence:` frontmatter field is auto-assigned (1 + max existing). The planning MCP's `next_atom(task)` verb returns the next `status: ready` atom in sequence order.

Sequential matches the single-agent reality and eliminates filesystem race conditions on claim. If you have a genuine parallel-atom workload, that's a Phase 4.x conversation; today, atoms hand off one at a time.

## Lg-mode-only

This command refuses to run if the project is in sm mode. To switch:

```
/start-planning "<phase name>" --mode lg
```

## See also

- `/start-planning` — initialize the planning structure (phase in lg)
- `/start-task` — add a task under a phase
- `docs/lg-mode.md` — full lg-mode layer model
- `docs/atom-granularity.md` — when to spawn an atom file vs. inline checkbox
