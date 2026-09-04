---
title: Validate success through comprehensive testing
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: [reclaim-non-symlink-skill-dirs-in-the-linker, version-the-executing-skill-artifact, warn-on-skill-drift-at-sessionstart, eliminate-silent-no-op-exits-in-relink-and-update, deliver-the-fix-on-update-not-just-on-install, remediate-already-stale-consumer-repos]
parallelizable: false
---

# Task: Validate success through comprehensive testing

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
Every guarantee this phase claims is covered by a test that fails if the guarantee breaks -- proven from a marketplace-shaped install, not only from `npm install`.

## Atoms

### Regression tests for the defect itself

- [x] `tests/run.sh`: real dir at `.claude/skills/persistent-planning/` -> run linker -> assert it becomes a symlink and `<name>.bak-*` holds the original contents
- [x] Assert the reclaim is non-destructive: seed a sentinel file in the real dir, assert it survives in the `.bak-*` copy
- [x] Assert idempotence: run the linker twice, assert exactly one `.bak-*` and no churn on the second pass
- [x] Assert a healthy symlink is left alone (the `antagonist-ai` case) -- no backup dir created, no relink
- [x] Assert `<prefix>_SKIP_LINK=1` and `<prefix>_NO_RECLAIM=1` both suppress reclaim
- [x] Assert a failed rename falls through to skip + loud warning rather than deleting anything

### Version marker and drift detection

- [x] Assert the linker writes `.version` beside `SKILL.md` and its value matches `package.json`
- [x] Assert `installedVersion()` prefers the skill marker over the `CLAUDE_PLUGIN_ROOT` fallback
- [x] Assert a missing marker degrades to current behavior, never throws
- [x] Assert SessionStart emits a drift nudge on marker != plugin version, and is silent when equal
- [x] Assert the nudge merges into a single valid `SessionStart` JSON response -- parse the stdout, don't string-match it
- [x] Assert the hook fails open: corrupt the marker, assert session start still succeeds

### No-op exits

- [x] Assert `update` on `(not installed)` exits non-zero and names every path probed
- [x] Assert `relink` resolves via the new `CLAUDE_PLUGIN_ROOT/scripts/link-skills.js` probe in a marketplace-shaped fixture
- [x] Assert no command in `bin/` exits 0 after a no-op

### End-to-end, marketplace-shaped

- [x] Build a fixture with **no `node_modules` in the plugin cache**, mirroring the real install shape
- [x] Stale dir in place -> plugin update -> next session -> assert dir reclaimed with no `npm install` anywhere in the path
- [x] Assert the migration stamp makes it run once per plugin version, not once per session
- [x] Assert `updatePolicy: off` performs no filesystem mutation

### The guarantee that started this

- [x] Generate a plan through the reclaimed skill and **`diff`** the output against the 3.1.0 template -- zero differences
- [x] Assert the generated plan contains Phase 5, Phase 6, **and** the `## On Completion` block
- [x] Assert the two closers are the last two entries, per the existing ordering assertion in `tests/run.sh`
- [x] Run the full `npm test` suite green before this task closes

## Decisions Made

**Result: 42 -> 74 assertions, 0 failures.** Every guarantee this phase claims now has a
test that fails if it breaks.

**One assertion resolved to its fallback branch, and that was informative**: the shipped
`skills/persistent-planning/` contains only `SKILL.md` — no `scripts/`, no `docs/`. The
stale copies carry `scripts/init-planning.sh` and `docs/` because that was the *v1*
layout. `commands/start-planning.md:75-76` still lists
`~/.claude/skills/persistent-planning/scripts/init-*.sh` as a fallback, which is exactly
the route by which a stale skill dir got executed. After reclaim that path no longer
resolves and the earlier `bash scripts/init-planning.sh` fallback takes over — correct,
but it leaves a dead path documented in `commands/`. Flagged for the docs pass rather
than changed here; touching command resolution is a separate risk.

**Assert by diff, never by feature-grep.** Triage on 2026-09-04 grepped the stale copies
for phase and closer keywords, got `phases: 6 | closers: 2`, and read as healthy. Only
`diff` against the source exposed the 23-line gap. Any test that counts keywords instead
of comparing content reproduces that blind spot.

**The fixture must be marketplace-shaped.** A test that passes under `npm install` proves
nothing about the population that is actually broken -- that shape has no `node_modules`
in the plugin cache and never runs postinstall.

**Parse the hook's JSON, don't string-match it.** The failure mode being guarded is an
invalid second response line; a substring assertion would pass on malformed output.

**Plain bash asserts, no framework.** `tests/run.sh` is 256 lines of bash running the
real scripts against `mktemp -d` workspaces. Match it -- see
`.documentation/testing/test-suite.md`.

## Status
**Currently done** -- 74 passed, 0 failed.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above. MANDATORY closer -- gates on every
preceding task and may never be `parallelizable: true`.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
