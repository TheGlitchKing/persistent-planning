# Persistent Planning

> Persistent markdown-based planning for Claude Code -- the context engineering pattern pioneered by Manus AI.

A Claude Code plugin that uses on-disk markdown files as "working memory" for planning, progress tracking, and knowledge storage. Plans persist across sessions and support multiple concurrent tasks.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blue)](https://github.com/TheGlitchKing/persistent-planning)

---

## Why This Plugin?

Claude Code (and most AI agents) suffer from:

- **Volatile memory** -- in-memory task tracking disappears on context reset
- **Goal drift** -- after 50+ tool calls, original goals get forgotten
- **Hidden errors** -- failures aren't tracked, so the same mistakes repeat
- **Context stuffing** -- everything crammed into context instead of stored on disk

Persistent Planning solves all of these with the same approach that made [Manus AI worth $2 billion](https://manus.im/de/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus): use the filesystem as external memory.

## The 3-File Pattern

For every complex task, create three files:

```
.planning/[task-name]/task_plan.md   -> Track phases and progress
.planning/[task-name]/notes.md       -> Store research and findings
[deliverable].md                     -> Final output
```

### The Loop

```
1. Create task_plan.md with goal and phases
2. Research -> save to notes.md -> update task_plan.md
3. Read notes.md -> create deliverable -> update task_plan.md
4. Deliver final output
```

**Key insight:** By reading `task_plan.md` before each decision, goals stay in the attention window. This is how Manus handles ~50 tool calls without losing track.

## Installation

### Option 1: NPM (Recommended)

```bash
# Install globally
npm install -g @theglitchking/persistent-planning
persistent-planning install --scope user

# Or via npx (no global install)
npx @theglitchking/persistent-planning install --scope user
```

### Option 2: Installer Script

```bash
git clone https://github.com/TheGlitchKing/persistent-planning.git
cd persistent-planning
./install.sh --scope user       # Available in all projects
# OR
./install.sh --scope project    # Current project only
```

### Option 3: Claude Marketplace

```
/plugin install TheGlitchKing/persistent-planning
```

### Option 4: Manual Installation

```bash
mkdir -p ~/.claude/skills
cp -r persistent-planning/skills/SKILL.md ~/.claude/skills/persistent-planning/SKILL.md
cp -r persistent-planning/scripts ~/.claude/skills/persistent-planning/scripts
cp -r persistent-planning/docs ~/.claude/skills/persistent-planning/docs
cp persistent-planning/.claude/commands/start-planning.md ~/.claude/commands/start-planning.md
```

## Usage

### Quick Start

```
/start-planning "Your task name here"
```

This creates:
```
.planning/
└── your-task-name/
    ├── task_plan.md    # Track phases and progress
    └── notes.md        # Store research and findings
```

### Session Persistence

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
```

Each task gets its own directory. No conflicts, no overwrites.

## Core Principles

| Principle | Implementation |
|-----------|----------------|
| Filesystem as memory | Store in files, not context |
| Attention manipulation | Re-read plan before decisions |
| Error persistence | Log failures in plan file |
| Goal tracking | Checkboxes show progress |
| Append-only context | Never modify history |

## When to Use

**Use for:**
- Multi-step tasks (3+ steps)
- Research tasks
- Building/creating projects
- Tasks spanning many tool calls

**Skip for:**
- Simple questions
- Single-file edits
- Quick lookups

## File Structure

```
persistent-planning/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── .claude/
│   └── commands/
│       └── start-planning.md    # /start-planning command
├── skills/
│   └── SKILL.md             # Core skill definition
├── scripts/
│   └── init-planning.sh     # Automated setup script
├── docs/
│   ├── reference.md         # Manus context engineering principles
│   └── examples.md          # Worked examples
├── install.sh               # Plugin installer
├── uninstall.sh             # Plugin uninstaller
├── plugin.json              # Root plugin metadata
├── README.md                # This file
├── LICENSE                  # MIT license
└── CHANGELOG.md             # Version history
```

## Cleanup

```bash
# Remove a single task's planning files
rm -rf .planning/[task-name]/

# Remove all planning files
rm -rf .planning/
```

## Acknowledgments

- **Manus AI** -- for pioneering context engineering patterns
- **Ahmad Othman Ammar Adi** ([OthmanAdi](https://github.com/OthmanAdi)) -- for the original [planning-with-files](https://github.com/OthmanAdi/planning-with-files) skill
- **Anthropic** -- for Claude Code and the skills framework

## License

MIT License -- see [LICENSE](./LICENSE)

---

**Author:** [TheGlitchKing](https://github.com/TheGlitchKing)
