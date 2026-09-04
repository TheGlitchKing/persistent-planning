---
title: Version the executing skill artifact
tier: plan
domains:
  - planning
status: ready
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: []
parallelizable: true
---

# Task: Version the executing skill artifact

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
The skill directory that actually executes carries its own version marker, so drift between the reported version and the running code is detectable in principle.

## Atoms

- [ ] Decide the marker: a `.version` file written by the linker beside `SKILL.md` (the skill dir has no `package.json` and should not gain a fake one)
- [ ] Write the marker on every link/reclaim in `linkSkills()`, sourced from `packageRoot/package.json`
- [ ] Teach `installedVersion()` to prefer the linked-skill marker over the `CLAUDE_PLUGIN_ROOT` fallback, so the version reported is the version that runs
- [ ] Keep the existing precedence for healthy installs: `node_modules` package.json -> skill marker -> `CLAUDE_PLUGIN_ROOT`
- [ ] Handle a symlinked skill dir: the marker resolves through the link to the package, so it is correct for free -- assert this rather than special-casing it
- [ ] Confirm a missing marker degrades to today's behavior, never to a crash

## Decisions Made

**`.version`, not `package.json`**: issue #10 proposed either. A `package.json` inside a
skill dir invites npm to treat it as a package and changes module resolution. A plain
`.version` file cannot.

**The point is comparing the right two things**: today `installedVersion()` reports
`CLAUDE_PLUGIN_ROOT`'s version (genuinely 3.1.0) while `/start-planning` runs
`.claude/skills/.../init-planning.sh` (pre-3.1.0). Same number, different artifact. The
marker makes those two comparable.

## Status
**Currently ready** -- independent of task 1; both touch `linkSkills` so land them in one PR if convenient.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true` -- safe for a subagent to pick up concurrently.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
