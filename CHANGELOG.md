# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2026-05-07

### Added — Lg-mode (large/team) layered planning

v3.0 introduces a new **layered planning mode** alongside the existing single-task flow. The mode is auto-detected (90-day git-author-count heuristic; ≥2 distinct authors → lg) and is sticky once chosen.

**Four layers** in lg mode:

- **Phase** — strategic grouping of related tasks (top)
- **Task** — bounded deliverable; declares `depends_on` + `parallelizable` for subagent team scheduling
- **Atom** — subagent hand-off unit; sequential within a task; status: `ready | in_progress | done | blocked` with reopen support
- **Notes** — cross-cutting references scoped to a phase or task

All four layers carry HEWTD-aligned frontmatter (`tier: plan`). `version` is intentionally omitted — HEWTD 2.2.0+ makes it conditionally optional for plan-tier docs.

### Added — `/start-task` and `/start-atom` slash commands

- `/start-task "<name>" --parent <phase>` — adds a task under an existing phase (lg only)
- `/start-atom "<name>" --parent <task>` — adds an atom (subagent hand-off unit) under a task (lg only); auto-resolves the parent phase by walking `.planning/`; auto-assigns sequence number
- `/start-planning` updated to dispatch sm vs lg based on detect-mode.sh; accepts `--mode sm|lg` for explicit override

### Added — `.planning/.meta/workspace.json`

Per-project mode tracker. Fields: `schema_version`, `mode`, `auto_detected`, `detected_contributors`, `created_at`. Bootstrapped on first lg-mode init. See `docs/workspace-json.md` for the full schema.

### Added — Documentation

- `docs/lg-mode.md` — full lg-mode guide
- `docs/atom-granularity.md` — anti-pattern guide for inline-checkbox-vs-standalone-atom
- `docs/workspace-json.md` — workspace.json schema reference

### Added — Scripts

- `scripts/detect-mode.sh` — sm/lg resolution
- `scripts/lib/planning.sh` — shared bash helpers
- `scripts/init-phase.sh`, `scripts/init-task.sh`, `scripts/init-atom.sh` — lg-mode init scripts

### Added — Templates

- `templates/lg/{phase,task,atom,notes}.md` — HEWTD-frontmattered layer templates

### Subagent contract (requires semantic-memory 1.0)

Lg-mode plans are designed to be read by subagents via semantic-memory's MCP verbs (registered conditionally on the `plans` corpus). When semantic-memory is absent, persistent-planning falls back to filesystem-based reads — slash commands still work; subagent comprehension degrades.

### Backwards compatibility

- **Sm mode preserved exactly**: existing `.planning/<task-slug>/{task_plan.md, notes.md}` directories continue to work without changes. The original `/start-planning "Task name"` flow is identical to v2.
- **Auto-detection is non-disruptive**: existing v2 plans aren't migrated. New `/start-planning` invocations auto-detect mode and create new artifacts using the resolved mode.

### Optional dependencies

- `@theglitchking/hit-em-with-the-docs ^2.2.0` — required for `hewtd validate` to accept lg-mode plan frontmatter (introduces `tier: "plan"` + conditional `version`)
- `@theglitchking/semantic-memory ^1.0.0` (formerly `semantic-sidekick`) — required for the planning MCP verbs that subagents use to read/mutate lg-mode plans

When neither is installed, lg mode still works as a pure file-authoring flow.

## [2.0.0] - 2026-04-18

### ⚠️ Breaking changes

v2.0.0 removes the hand-rolled `persistent-planning install|uninstall`
flow in favor of standard Claude Code plugin distribution and npm install
paths. Plugin skill and command files are now delivered **automatically**
— no manual copy step.

**If you're an existing v1 user**, here's what to expect and how to
upgrade:

- `persistent-planning install --scope user` is gone. Install instead via
  the plugin marketplace:

  ```
  /plugin marketplace add TheGlitchKing/persistent-planning
  /plugin install persistent-planning@persistent-planning-marketplace
  ```

  Or, for a project-local install that's visible to teammates and CI:

  ```
  npm install --save-dev @theglitchking/persistent-planning
  ```

- `persistent-planning uninstall` is gone. Use `/plugin uninstall` or
  `npm uninstall @theglitchking/persistent-planning` depending on how you
  installed it.

- **Old skill/command files in `~/.claude/` or `./.claude/`** placed by
  v1's installer will keep working until you remove them — but the
  marketplace plugin and the npm postinstall both place their own copies,
  so to avoid duplication you should delete the manually-installed
  copies once you've adopted v2:

  ```
  # If you installed with --scope user:
  rm -rf ~/.claude/skills/persistent-planning
  rm ~/.claude/commands/start-planning.md

  # If you installed with --scope project:
  rm -rf .claude/skills/persistent-planning
  rm .claude/commands/start-planning.md
  ```

- The old `install`/`uninstall` subcommands still exist as deprecation
  shims — running them prints a migration pointer and exits cleanly
  instead of failing.

### Added
- Adopts `@theglitchking/claude-plugin-runtime` for postinstall skill
  symlinking, SessionStart update nudge/auto-apply, and standardized
  `update`/`policy`/`status`/`relink` CLI subcommands.
- Default `updatePolicy: "nudge"` — on session start, the plugin checks
  npm for a newer version and prints a one-liner when one exists. Opt
  into `auto` for background auto-update, or `off` to silence entirely.
- Four new slash commands: `/persistent-planning:update`,
  `/persistent-planning:policy`, `/persistent-planning:status`,
  `/persistent-planning:relink`.

### Changed
- **Skill layout**: `skills/SKILL.md` moved to
  `skills/persistent-planning/SKILL.md` so the runtime can symlink it
  into consuming projects' `.claude/skills/persistent-planning/`.
- **Slash command location**: `.claude/commands/start-planning.md` moved
  to `commands/start-planning.md` (top-level, matching the marketplace
  plugin convention).
- Node >= 20 required (was >= 16).

### Removed
- `install.sh`, `uninstall.sh`, and the `postinstall.js` banner script.
- The root-level `plugin.json` — manifest is now only at
  `.claude-plugin/plugin.json`.

## [1.0.0] - 2026-02-12

### Added
- Core skill definition (`skills/SKILL.md`) with persistent markdown-based planning
- `/start-planning` slash command for one-command setup
- `init-planning.sh` script for automated `.planning/` directory creation
- Task-specific subdirectories (`.planning/[task-slug]/`)
- `task_plan.md` and `notes.md` templates
- Multiple concurrent task support
- Reference documentation on Manus context engineering principles
- Worked examples for research, bug fix, and feature development workflows
- `install.sh` installer with user/project scope support
- `uninstall.sh` for clean removal
- Plugin manifest files for marketplace compatibility

### Based On
- Context engineering principles from [Manus AI](https://manus.im/de/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- Original [planning-with-files](https://github.com/OthmanAdi/planning-with-files) skill by Ahmad Othman Ammar Adi
