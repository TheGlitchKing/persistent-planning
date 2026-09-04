# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2026-09-04

### Fixed — Stale skill directories run frozen code (#10)

A consumer repo could run a **pre-3.1.0 copy** of the skill indefinitely while the update
check reported the current version — no nudge, no warning, exit 0 everywhere. Plans
generated that way silently omitted the mandatory validate and documentation phases and
the entire `## On Completion` archive block: precisely the guarantees 3.1.0 was released
to make.

**Cause.** v1's `persistent-planning install` (removed in 2.0.0) *copied*
`skills/persistent-planning/` into `.claude/skills/`. The v2+ linker only symlinks, and
when it finds a real directory at the destination it warns and skips — permanently. So
`installedVersion()` reported the plugin's version while `/start-planning` executed the
skill dir's frozen copy. Two artifacts, nothing reconciling them. (The linker was never
copying, as first reported; it was refusing to reclaim what v1 left behind.)

- **Reclaim instead of skip** — `scripts/lib/skill-link.js` renames a real directory to
  `<name>.bak-<ISO8601>` before the runtime's linker runs, leaving a clean destination it
  then symlinks normally. Nothing is ever deleted; a failed rename falls through to the
  old skip but says so loudly and names the fix. Idempotent — a healthy symlink is left
  alone, so a second run makes no second backup. Opt out with
  `PERSISTENT_PLANNING_NO_RECLAIM=1`.
- **The drift is detectable now.** The primary signal is structural: a real directory at
  `.claude/skills/<name>` is *always* drift, because nothing in the current system creates
  one. A `.version` marker beside `SKILL.md` is the secondary signal — how far behind a
  drifted copy is, and the only signal available where symlinks are impossible. Only
  healthy symlinks are stamped; stamping a stale copy would mark it current.
- **SessionStart reports it**, naming the path, the running vs installed version, the
  user-visible consequence, and `npx persistent-planning relink`. Merged into the existing
  single JSON response; fails open; silent under `updatePolicy: off`.
- **SessionStart repairs it under `updatePolicy: auto`**, once per plugin version. This is
  the part that reaches the installs that are actually broken: a marketplace install has
  no `node_modules` in the plugin cache and **never runs npm postinstall**, so a fix
  shipped only through postinstall would reach nobody affected. The hook is the one thing
  that runs every session in that shape. `nudge` warns without touching the filesystem;
  `off` does nothing at all.
- **No more clean exits for no-ops.** `update` with no managed install exits 1 and lists
  every path probed, instead of printing `(not installed)` twice and exiting 0. `relink`
  gained `CLAUDE_PLUGIN_ROOT/scripts/` and self-package probes — it previously could not
  run at all in a marketplace-only install, the shape that needs it most — and no longer
  swallows the linker's exit code.

Test suite grows to 63 assertions, including a marketplace-shaped fixture with no
`node_modules`. New docs: `.documentation/troubleshooting/stale-skill-dir-drift.md`,
`.documentation/architecture/skill-linking-and-reclaim.md`,
`.documentation/reference/skill-version-marker.md`,
`.documentation/procedures/plugin-update-delivery.md`.

## [3.1.0] - 2026-08-31

### Added — Status tracking and completion archive (#4)

Plans now report their own completion, and completed plans get retired out of the active tree.

**Completion is derived, not declared.** A plan is COMPLETE when every checkbox under it is checked, or when its top-level artifact (`phase.md` / `task_plan.md` / `task.md`) declares `status: done`. Nothing has to be remembered or kept in sync — checking the last box *is* the signal. Combined with the mandatory closing phases above, a plan cannot read COMPLETE until its work has been tested and documented.

- `scripts/plan-status.sh` — the single implementation of the scan. Default output is a table (`in progress` / `blocked` / `COMPLETE` / `empty` / `archived` with a checked/total count); `--complete` prints one complete slug per line; `--nudge` prints a one-line notice or nothing.
- `scripts/archive-plan.sh` — moves `.planning/<slug>/` to `.planning/.archive/<slug>/`, ensures that path is gitignored, and stamps the top-level artifact `status: archived` + `archived_on` (or a dated footer for sm plans without frontmatter). Prefers `git mv` when the plan is tracked. Refuses incomplete plans unless `--force`; also supports `--all-complete` and `--dry-run`. Nothing is ever deleted.
- `hooks/session-start.js` — now surfaces complete-but-unarchived plans in the session's context. It merges the notice into the runtime's single `SessionStart` response by intercepting that one stdout write, since the runtime exposes no append hook and a second response line would be invalid; it fails open, so the update check is unaffected if the payload isn't the expected shape.
- `/plan-status` and `/archive-plan` slash commands.
- Both plan templates gained an `## On Completion` section stating the rule and the archive command, so an agent reading only the plan still learns the protocol.

`.planning/.archive/` is gitignored on purpose: a completed plan is local history. Anything worth sharing gets promoted into a real doc by the mandatory documentation phase.

Test suite grows to 42 assertions. New doc: `.documentation/procedures/plan-completion-and-archive.md`.

### Added — Mandatory closing phases (#5)

Every plan now ends with the same two units of work, seeded by the templates so an agent never has to remember them:

1. **Validate success through comprehensive testing**
2. **Documentation pass — create/update/deprecate docs**

- **sm mode**: `task_plan.md` seeds 6 phases instead of 4; phases 5 and 6 are the mandatory pair, marked `MANDATORY`.
- **lg mode**: `templates/lg/phase.md` seeds the pair as the last two task checkboxes. A phase cannot be marked `done` until both are `done`, and neither may be `parallelizable`.
- Both templates carry the ordering rule inline: new work is inserted **above** the pair, never after it.

### Added — Test suite

`tests/run.sh` — plain bash asserts (no framework), wired to `npm test`. 21 assertions covering sm/lg init, the closing-phase ordering, slug conversion, template placeholder substitution, atom sequence auto-increment, idempotent re-runs, and the lg-mode guard on `init-phase.sh`.

### Changed — Documentation moved to hit-em-with-the-docs

`docs/` is gone; documentation now lives in a hewtd-managed `.documentation/` tree, split by domain:

| Was | Now |
|---|---|
| `docs/lg-mode.md` | `.documentation/architecture/lg-mode.md` |
| `docs/reference.md` | `.documentation/architecture/context-engineering-principles.md` |
| `docs/atom-granularity.md` | `.documentation/standards/atom-granularity.md` |
| `docs/workspace-json.md` | `.documentation/reference/workspace-json.md` |
| `docs/examples.md` | `.documentation/quickstart/examples.md` |

New docs: `.documentation/standards/mandatory-closing-phases.md` and `.documentation/testing/test-suite.md`. A custom `reference` domain is registered in `.claude/hit-em-with-the-docs.json`. The npm `files` array now ships `.documentation/` in place of `docs/`.

Links in older CHANGELOG entries still point at the old `docs/` paths; they are left as written, since they describe the layout as it was at those releases.

## [3.0.1] - 2026-05-08

### Fixed
- **Critical: lg-mode init scripts and templates were excluded from the npm package.** The 3.0.0 release had `scripts/link-skills.js` (singular file) in the package.json `files` array instead of `scripts/` (whole dir), and `templates/` was missing entirely. As a result, users installing v3.0.0 got the slash command markdown but the underlying `init-phase.sh`, `init-task.sh`, `init-atom.sh`, `detect-mode.sh`, `lib/planning.sh`, and the four lg-mode templates (`phase.md`, `task.md`, `atom.md`, `notes.md`) were all missing — meaning lg mode silently broke on first invocation.

  This patch updates the `files` array to include `scripts/` and `templates/` directories, and bumps to 3.0.1. v3.0.0 should be considered broken; consumers should upgrade to 3.0.1 immediately.

### How this happened
The `files` array was the legacy v2 contents (which only needed `scripts/link-skills.js`). When v3.0 added new scripts and templates I missed updating the array. Caught when verifying the published 3.0.0 tarball contents.

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
