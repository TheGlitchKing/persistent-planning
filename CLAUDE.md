# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Claude Code **plugin** (not an app): markdown skills, slash commands, bash init scripts, and a thin CLI. There is no build step and no bundler. "Running" it means invoking the shell scripts or the CLI directly.

```bash
npm test                                       # tests/run.sh — bash smoke tests over the init scripts

# Exercise the init scripts (they write into $CLAUDE_PROJECT_DIR or $PWD)
bash scripts/detect-mode.sh --explain          # prints sm|lg + why
bash scripts/init-planning.sh "Some task"      # sm mode
bash scripts/init-phase.sh "Some phase"        # lg mode (refuses in sm)
bash scripts/init-task.sh  "Some task" --parent <phase-slug>
bash scripts/init-atom.sh  "Some atom" --parent <task-slug>
PLANNING_FORCE=1 bash scripts/init-task.sh ... # overwrite existing artifacts

# CLI (update/policy/status/relink; most logic lives in claude-plugin-runtime)
node bin/persistent-planning.js status
node scripts/link-skills.js                    # postinstall: symlink skills into .claude/skills/
```

`tests/run.sh` is plain bash asserts (no framework) running the real scripts against `mktemp -d` workspaces — see `.documentation/testing/test-suite.md`. Ad-hoc: `CLAUDE_PROJECT_DIR=/tmp/pp-test bash scripts/init-phase.sh "X"`. The scripts are idempotent — they skip existing files and warn rather than overwrite.

## Architecture

**Two distribution paths, one tree.** The same directory ships as a Claude Code marketplace plugin (`.claude-plugin/plugin.json` + `marketplace.json`, loaded via `${CLAUDE_PLUGIN_ROOT}`) *and* as an npm package (`postinstall` → `scripts/link-skills.js` symlinks `skills/` into the consuming project's `.claude/skills/` and registers the SessionStart hook). Anything a user needs at runtime must exist in **both** paths.

**Runtime is delegated.** `bin/persistent-planning.js`, `hooks/session-start.js`, and `scripts/link-skills.js` are ~20-line shims over `@theglitchking/claude-plugin-runtime` (update policy, postinstall linking, hook registration). Don't reimplement update/policy/link logic here — it belongs upstream.

**Behavior lives in markdown, not code.** `skills/persistent-planning/SKILL.md` is the pattern (filesystem-as-working-memory, Manus-style). `commands/*.md` are prompt files that tell Claude which bash script to shell out to, with fallback paths for the marketplace vs npm vs `~/.claude/skills/` install locations. Editing behavior usually means editing markdown.

### sm vs lg mode

`scripts/detect-mode.sh` resolves mode: `.planning/.meta/workspace.json` `"mode"` wins (sticky override), else ≥2 distinct git authors in 90 days → `lg`, else `sm`. Git failure or non-repo → `sm`.

- **sm** (`init-planning.sh`): `.planning/<slug>/{task_plan.md, notes.md}`. Self-contained — heredoc templates inline, its own slugify copy, no `lib/planning.sh`. **This is v2 behavior preserved bit-for-bit; do not refactor it into the shared lib.**
- **lg** (`init-phase.sh` / `init-task.sh` / `init-atom.sh`): four layers — phase → task → atom, plus notes as cross-cutting (not hierarchical) context at phase or task scope. All three source `scripts/lib/planning.sh` and render `templates/lg/*.md` via `planning_render_and_log`. All three hard-refuse when mode ≠ lg.

Layer vocabulary is canonical (**phase / task / atom / notes**) and appears in templates, docs, and command descriptions — keep it consistent. Scheduling default is dependencies-first (`depends_on:`) then parallelism (`parallelizable: true` only when no inter-deps). Atoms are sequential within a task; `init-atom.sh` auto-assigns `sequence:` as max+1 by grepping sibling atom files, and resolves the parent phase by walking `.planning/*/<task-slug>/task.md`.

**Frontmatter contract.** Every `templates/lg/*.md` artifact carries HEWTD 2.2.0+ frontmatter with `tier: plan` and `plan_kind: phase|task|atom`; `version` is deliberately omitted (optional for plan tier). Status enums differ by layer: phase/task use `draft|active|paused|done|archived`, atoms use `ready|in_progress|done|blocked` (+ reopen with `reopened_at:`). This frontmatter is what makes plans readable by semantic-memory's MCP for subagent hand-off — changing it breaks that integration.

**Template rendering** is sed placeholder substitution (`FOO_PLACEHOLDER=value` args). Template dir is resolved as `$CLAUDE_PROJECT_DIR/templates/lg` first, then `$SCRIPT_DIR/../templates/lg` — the second is the real path for installed users; keep both fallbacks when touching path logic.

**Every plan ends with two mandatory phases** — validate via testing, then a documentation pass — seeded into `scripts/init-planning.sh` (sm, phases 5-6) and `templates/lg/phase.md` (lg, closing tasks). They must stay last; `tests/run.sh` asserts the ordering. Rationale in `.documentation/standards/mandatory-closing-phases.md`.

**Docs are hewtd-managed.** They live in `.documentation/<domain>/`, not `docs/`. Create with `npx hewtd integrate <file> -a`, retire with `npx hewtd archive <file>`, regenerate indexes with `npx hewtd maintain --quick`. `INDEX.md`/`REGISTRY.md` are generated — editing them by hand is denied by a guard and overwritten anyway. A custom `reference` domain is registered in `.claude/hit-em-with-the-docs.json`.

## Release checklist

Version appears in **three** places and they must match: `package.json`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json` (both the `metadata.version` and the plugin entry).

The `files` array in `package.json` gates what npm consumers actually get. v3.0.0 shipped broken because `scripts/` and `templates/` were missing from it — new runtime directories must be added there, and the published tarball verified (`npm pack` + inspect) before release.

Every release gets a `CHANGELOG.md` entry.
