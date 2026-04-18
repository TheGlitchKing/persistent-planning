---
name: persistent-planning
description: Transforms workflow to use persistent markdown files for planning, progress tracking, and knowledge storage. Use when starting complex tasks, multi-step projects, research tasks, or when the user mentions planning, organizing work, tracking progress, or wants structured output.
---

# Persistent Planning

Use persistent markdown files as your "working memory on disk" -- the context engineering pattern pioneered by Manus AI.

---

## Quick Start

### Automatic Setup (Recommended)

Start planning in one command:

```
/start-planning "Your task name here"
```

This automatically:
- Creates `.planning/` directory
- Creates `.planning/[task-slug]/task_plan.md` with templates
- Creates `.planning/[task-slug]/notes.md` with templates
- Files persist across ALL future sessions

**Example:**
```
/start-planning "Refactor authentication system"
```

### Manual Setup

If `/start-planning` isn't available:

1. Create `.planning/[task-slug]/` directory
2. Create `task_plan.md` with goal and phases
3. Define phases with checkboxes
4. Update after each phase -- mark `[x]` and change status
5. Read before deciding -- refresh goals in attention window

---

## Persistence and Concurrent Tasks

Unlike in-memory task tracking (which disappears between sessions), your plans **stay on disk** and **support multiple concurrent tasks**.

### Persistence Across Sessions

**Session 1:**
```
/start-planning "Complex feature"
[Work, update plans]
```

**Session 2 (next day):**
```
Read .planning/complex-feature/task_plan.md  <- Plans are still here
Read .planning/complex-feature/notes.md      <- Notes are still here
[Continue work]
```

### Multiple Concurrent Tasks

```
/start-planning "Refactor authentication"
  -> Creates .planning/refactor-authentication/

/start-planning "Fix memory leak"
  -> Creates .planning/fix-memory-leak/

Both plans coexist without overwriting each other.
```

Each task gets its own directory. No conflicts, no overwrites.

## The 3-File Pattern (Per Task)

For every task, files are created in a **task-specific directory**:

| Location | Purpose | When to Update |
|----------|---------|----------------|
| `.planning/[task-name]/task_plan.md` | Track phases and progress | After each phase |
| `.planning/[task-name]/notes.md` | Store findings and research | During research |
| `[deliverable].md` | Final output (root directory) | At completion |

**Example structure:**
```
.planning/
├── refactor-auth/
│   ├── task_plan.md
│   └── notes.md
├── fix-memory-leak/
│   ├── task_plan.md
│   └── notes.md
└── performance-optimization/
    ├── task_plan.md
    └── notes.md
```

## Core Workflow

```
Loop 0: Run /start-planning "Task name" (creates task directory automatically)
Loop 1: Define phases in .planning/[task-name]/task_plan.md
Loop 2: Research -> save to .planning/[task-name]/notes.md -> update plan
Loop 3: Read notes -> create deliverable -> update plan
Loop 4: Deliver final output
Loop 5: Next task? Run /start-planning again (no conflicts)
```

### The Loop in Detail

**Before each major action:**
```bash
Read .planning/[task-name]/task_plan.md  # Refresh goals in attention window
```

**After each phase:**
```bash
Edit .planning/[task-name]/task_plan.md  # Mark [x], update status
```

**When storing information:**
```bash
Write .planning/[task-name]/notes.md     # Don't stuff context, store in file
```

### Managing Multiple Tasks

**Task 1:**
```bash
Read .planning/refactor-auth/task_plan.md
Edit .planning/refactor-auth/notes.md
Edit .planning/refactor-auth/task_plan.md
```

**Task 2 (same session, no conflicts):**
```bash
Read .planning/fix-memory-leak/task_plan.md
Edit .planning/fix-memory-leak/notes.md
Edit .planning/fix-memory-leak/task_plan.md
```

Both tasks coexist independently. Switch between them as needed.

## task_plan.md Template

Create this file FIRST for any complex task:

```markdown
# Task Plan: [Brief Description]

## Goal
[One sentence describing the end state]

## Phases
- [ ] Phase 1: Plan and setup
- [ ] Phase 2: Research/gather information
- [ ] Phase 3: Execute/build
- [ ] Phase 4: Review and deliver

## Key Questions
1. [Question to answer]
2. [Question to answer]

## Decisions Made
- [Decision]: [Rationale]

## Errors Encountered
- [Error]: [Resolution]

## Status
**Currently in Phase X** - [What I'm doing now]
```

## notes.md Template

For research and findings:

```markdown
# Notes: [Topic]

## Sources

### Source 1: [Name]
- URL: [link]
- Key points:
  - [Finding]
  - [Finding]

## Synthesized Findings

### [Category]
- [Finding]
- [Finding]
```

## Critical Rules

### 1. Always Create .planning/ Directory First
Create the `.planning/` directory before starting any complex task. Then create `task_plan.md`. This is non-negotiable.

### 2. Read Before Decide
Before any major decision, read the plan file. This keeps goals in your attention window.

### 3. Update After Act
After completing any phase, immediately update the plan file:
- Mark completed phases with `[x]`
- Update the Status section
- Log any errors encountered

### 4. Store, Don't Stuff
Large outputs go to files, not context. Keep only paths in working memory.

### 5. Log All Errors
Every error goes in the "Errors Encountered" section. This builds knowledge for future tasks.

### 6. Easy Cleanup
When a task is complete, delete the task directory:
```bash
rm -rf .planning/[task-name]/
```

Or clean up everything:
```bash
rm -rf .planning/
```

## When to Use This Pattern

**Use 3-file pattern for:**
- Multi-step tasks (3+ steps)
- Research tasks
- Building/creating something
- Tasks spanning multiple tool calls
- Anything requiring organization

**Skip for:**
- Simple questions
- Single-file edits
- Quick lookups

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| Use volatile task tracking for persistence | Use `/start-planning` for on-disk persistence |
| Put planning files in root | Use `.planning/[task-name]/` subdirectories |
| State goals once and forget | Re-read plan before each decision |
| Hide errors and retry | Log errors to plan file |
| Stuff everything in context | Store large content in files |
| Overwrite previous plans | Use `/start-planning` (auto-creates unique task dir) |
| Start executing immediately | Run `/start-planning "task name"` FIRST |
| Switch tasks without saving | Update task_plan.md before switching |

## Advanced Patterns

See [reference.md](../docs/reference.md) for:
- Attention manipulation techniques
- Error recovery patterns
- Context optimization principles

See [examples.md](../docs/examples.md) for:
- Real task examples
- Complex workflow patterns
