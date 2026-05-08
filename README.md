# Persistent Planning

> Persistent markdown-based planning for Claude Code -- the context engineering pattern pioneered by Manus AI.

A Claude Code plugin that uses on-disk markdown files as "working memory" for planning, progress tracking, and knowledge storage. Plans persist across sessions and support multiple concurrent tasks.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blue)](https://github.com/TheGlitchKing/persistent-planning)

> [!NOTE]
> **New in 3.0.0 — sm/lg modes + layered planning.** Solo work and quick spikes still get the original single-task flow (now called **sm mode**). Multi-week projects with multiple contributors get a new **lg mode** with layered phase / task / atom / notes artifacts that subagents can pick up via [semantic-memory](https://github.com/TheGlitchKing/semantic-sidekick)'s MCP. Mode is auto-detected from 90-day git author count; sm preserved bit-for-bit from v2. See [`docs/lg-mode.md`](./docs/lg-mode.md) for the layered model + [`docs/atom-granularity.md`](./docs/atom-granularity.md) for the inline-checkbox-vs-standalone-atom decision rule.
>
> Two new slash commands ship in 3.0: `/start-task "Name" --parent <phase>` and `/start-atom "Name" --parent <task>` (lg-mode only). `/start-planning` now dispatches to either flow based on detected mode (with `--mode sm|lg` override).
>
> All lg-mode artifacts carry [HEWTD](https://github.com/TheGlitchKing/hit-em-with-the-docs) 2.2.0+ frontmatter (`tier: "plan"`).

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

> **v1 → v2 breaking change**: the hand-rolled `persistent-planning install --scope ...` flow was removed. Skills and slash commands are now placed automatically — either by the Claude Code plugin marketplace, or by npm's postinstall symlinking. See [CHANGELOG.md](./CHANGELOG.md) for the full migration guide.

### Option A: Claude Code Plugin Marketplace (Recommended)

```
/plugin marketplace add TheGlitchKing/persistent-planning
/plugin install persistent-planning@persistent-planning-marketplace
```

### Option B: Project-level npm install

Pins the exact version in `package.json`, visible to teammates, CI, and LLMs reading the repo. Postinstall symlinks `skills/persistent-planning/` into `<project>/.claude/skills/`, writes a default `.claude/persistent-planning.json` (update policy `nudge`), and registers a SessionStart hook in `.claude/settings.json` if one is present. Dedup: if the plugin marketplace version is already enabled in `~/.claude/settings.json`, the npm hook registration is skipped.

```bash
npm install --save-dev @theglitchking/persistent-planning
```

### Option C: Try it (no install)

```bash
npx @theglitchking/persistent-planning status
```

## Update management

Each install ships with an update policy. By default the plugin checks npm at session start and prints a one-liner when a newer version is available — no changes made. Opt into automatic updates or silence the check entirely:

```bash
# Slash commands
/persistent-planning:policy auto    # auto-update on session start
/persistent-planning:policy nudge   # one-liner nudge only (default)
/persistent-planning:policy off     # silent

# CLI equivalents
npx --no @theglitchking/persistent-planning policy auto
npx --no @theglitchking/persistent-planning status     # installed, latest, policy, hook state
npx --no @theglitchking/persistent-planning update     # runs npm update + relinks skills
npx --no @theglitchking/persistent-planning relink     # re-symlink skills only
```

Policy resolution order: `PERSISTENT_PLANNING_UPDATE_POLICY` env var → `<project>/.claude/persistent-planning.json` → default `nudge`.

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
│   └── plugin.json          # Plugin manifest (marketplace loader)
├── bin/
│   └── persistent-planning.js  # CLI (update/policy/status/relink)
├── commands/
│   ├── start-planning.md    # /start-planning slash command
│   ├── update.md            # /persistent-planning:update
│   ├── policy.md            # /persistent-planning:policy
│   ├── status.md            # /persistent-planning:status
│   └── relink.md            # /persistent-planning:relink
├── hooks/
│   ├── hooks.json           # SessionStart hook manifest
│   └── session-start.js     # Runtime-delegated hook
├── scripts/
│   └── link-skills.js       # Postinstall (runtime-delegated)
├── skills/
│   └── persistent-planning/
│       └── SKILL.md         # Core skill definition
├── docs/
│   ├── reference.md         # Manus context engineering principles
│   └── examples.md          # Worked examples
├── README.md
├── LICENSE
└── CHANGELOG.md
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
