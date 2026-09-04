---
title: Version the executing skill artifact
tier: plan
domains:
  - planning
status: done
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

- [x] Marker is a `.version` file beside `SKILL.md` — not a `package.json`, which would change module resolution inside a skill dir
- [x] `writeVersionMarkers()` stamps from `package.json` after the linker runs
- [x] **Only healthy symlinks are stamped, never a real directory** — stamping a stale copy would mark it current and defeat the check
- [x] `readSkillVersion()` reads the version of the copy that would actually execute
- [x] Symlinked dir resolves through the link to the package, so it is correct for free — asserted, not special-cased (`describeSkill` also accepts an absolute-path symlink that resolves to the same place)
- [x] Missing marker degrades to "unknown", never throws; a read-only package dir simply leaves it absent
- [x] `skills/*/.version` gitignored so a local install cannot commit a stray marker

## Decisions Made

**The primary drift signal is structural, not the version number** (refinement made
during implementation): `describeSkill()` asks whether `.claude/skills/<name>` is a
symlink into this package. A **real directory is always drift**, because nothing in the
current system creates one — only v1's removed installer did. That check needs no marker
and cannot go stale. The marker is the *secondary* signal: it says how far behind a
drifted copy is, and it is the only signal available on install shapes where a symlink is
impossible (Windows without developer mode, some CI checkouts).

**`installedVersion()` was left alone.** The original atom proposed teaching the runtime's
`installedVersion()` to prefer the marker. That is an upstream change, and with the
structural check in place it buys nothing here — our own drift check reads the marker
directly. Left for the upstream fix if `src/index.ts:234` is ever addressed there.

**`.version`, not `package.json`**: issue #10 proposed either. A `package.json` inside a
skill dir invites npm to treat it as a package and changes module resolution. A plain
`.version` file cannot.

**The point is comparing the right two things**: today `installedVersion()` reports
`CLAUDE_PLUGIN_ROOT`'s version (genuinely 3.1.0) while `/start-planning` runs
`.claude/skills/.../init-planning.sh` (pre-3.1.0). Same number, different artifact. The
marker makes those two comparable.

## Status
**Currently done** -- marker written by `scripts/link-skills.js`, read by `scripts/lib/skill-link.js`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true` -- safe for a subagent to pick up concurrently.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
