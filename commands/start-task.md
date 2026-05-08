---
name: start-task
description: "Add a task under an existing phase in lg-mode persistent-planning. Creates .planning/<phase>/<task-slug>/{task.md, notes.md, atoms/}. Requires --parent <phase-slug>. Lg mode only."
---

# /start-task

Add a task under an existing phase. **Lg mode only** — refuses to run in sm mode.

---

## Usage

```
/start-task "Task name" --parent <phase-slug>
```

## Examples

```
/start-task "HEWTD schema extension" --parent foundation
/start-task "Multi-corpus refactor" --parent semantic-memory-core
/start-task "Drift detection algorithm" --parent ecosystem-extensions
```

---

## What To Do

When the user runs `/start-task "<name>" --parent <phase-slug>`:

1. Run the init script:
```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/../scripts"
bash "${SCRIPT_DIR}/init-task.sh" "<name>" --parent "<phase-slug>"
```

If the script isn't found at that path, try:
```bash
bash scripts/init-task.sh "<name>" --parent "<phase-slug>"
bash ~/.claude/skills/persistent-planning/scripts/init-task.sh "<name>" --parent "<phase-slug>"
```

2. After completion, remind the user:
   - Edit `.planning/<phase>/<task-slug>/task.md` to define the task goal
   - Add atoms with `/start-atom "<name>" --parent <task-slug>` (or inline checkboxes for simple atoms)
   - Update task frontmatter: `depends_on: [<other-task-slug>]` for sequential dependencies, or `parallelizable: true` for tasks with no inter-dependencies

---

## What It Creates

```
.planning/<phase-slug>/
└── <task-slug>/
    ├── task.md            # HEWTD-frontmattered task artifact (parent: <phase-slug>)
    ├── notes.md           # Cross-cutting notes scoped to this task
    └── atoms/             # Empty dir for future atoms (subagent hand-off units)
```

## Frontmatter scheduling fields

The `task.md` template includes two key scheduling fields:

- `depends_on: []` — array of other task slugs (within the same phase) this task depends on. The planning MCP's `next_task()` verb respects this graph.
- `parallelizable: false` — set to `true` for tasks that can be picked up in any order by subagent teams. Default `false` (conservative).

## Lg-mode-only

This command refuses to run if the project is in sm mode. To switch:

```
/start-planning "<phase name>" --mode lg
```

That writes `.planning/.meta/workspace.json` with `mode: "lg"` and creates the first phase.

## See also

- `/start-planning` — initialize the planning structure (phase in lg, task in sm)
- `/start-atom` — add an atom under a task
- `docs/lg-mode.md` — full lg-mode layer model
- `docs/atom-granularity.md` — when to spawn an atom file vs. add an inline checkbox
