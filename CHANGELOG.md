# Changelog

All notable changes to this project will be documented in this file.

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
