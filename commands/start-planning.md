---
name: start-planning
description: "Initialize persistent planning structure for a task. Creates .planning/[task-slug]/ with task_plan.md and notes.md for on-disk working memory that persists across sessions."
---

# /start-planning

Initialize the persistent planning structure for a task.

---

## Usage

```
/start-planning "Your task name here"
```

## Examples

```
/start-planning "Refactor authentication system"
/start-planning "Build REST API with JWT"
/start-planning "Fix memory leak in worker process"
```

---

## What To Do

When the user runs `/start-planning "Task Name"`:

1. Run the init script:
```bash
bash "$(dirname "$(readlink -f "$0")")/../scripts/init-planning.sh" "Task Name"
```

If the script is not found at that path, try these fallbacks in order:
```bash
bash scripts/init-planning.sh "Task Name"
bash ~/.claude/skills/persistent-planning/scripts/init-planning.sh "Task Name"
```

2. After the script completes, remind the user:
   - Edit `.planning/[task-slug]/task_plan.md` to define phases
   - Update the Status section as they work
   - Save findings to `.planning/[task-slug]/notes.md`
   - Re-read `task_plan.md` before major decisions

---

## What It Creates

```
.planning/
└── [task-slug]/
    ├── task_plan.md    # Track phases and progress
    └── notes.md        # Store research and findings
```

## Task Slug Conversion

Task names are converted to URL-friendly slugs:
- "Refactor Authentication" -> `refactor-authentication`
- "Build REST API" -> `build-rest-api`
- "Fix Bug #123" -> `fix-bug-123`
