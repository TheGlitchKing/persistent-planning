---
title: Skill linking and reclaim
tier: reference
domains:
  - architecture
audience:
  - developers
tags: []
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: How the skill directory reaches a consumer repo as a symlink, the four states it can
  be in, and how a stale real directory is reclaimed without ever deleting it.
estimated_read_time: 2 minutes
word_count: 348
last_validated: '2026-09-04'
backlinks: []
---

# Skill linking and reclaim

How `skills/persistent-planning/` reaches a consumer repo, and how a stale copy is
reclaimed. Implemented in `scripts/lib/skill-link.js` and `scripts/link-skills.js`.

## The link

`scripts/link-skills.js` runs as npm `postinstall` and delegates to
`@theglitchking/claude-plugin-runtime`'s `runPostinstall()`, which symlinks each
directory under `skills/` into the consumer's `.claude/skills/`.

The runtime's linker reconciles a symlink but **skips a real directory** — it warns
and moves on, every time, forever. That is correct caution (the directory might be
hand-managed) and it is also how v1 debris survived five months: v1's
`persistent-planning install`, removed in 2.0.0, *copied* the skill dir, and nothing
since could reclaim it.

## The reclaim

`reclaimStaleSkillDirs()` runs **before** the delegation. It renames a real directory
to `<name>.bak-<ISO8601>`, which leaves a clean destination the runtime's linker then
symlinks normally.

That ordering is the whole trick — it needs no change to `claude-plugin-runtime`, so
the fix ships as one release of this package rather than a runtime publish plus a
coordinated rollout. The runtime's skip is still worth fixing upstream; this shim is
written to be harmless if that ever lands.

Rules the implementation holds to:

- **Never delete.** A failed rename falls through to the runtime's old skip, but says
  so loudly and names `relink`. The directory may contain hand edits.
- **Idempotent.** A healthy symlink is left completely alone, so a second run makes no
  second backup.
- **Best-effort.** Any failure is caught; a reclaim problem never blocks an install.

## The four states

`describeSkill()` classifies `.claude/skills/<name>`:

| State | Meaning |
|---|---|
| `absent` | nothing there; the linker will create the symlink |
| `symlink-ok` | points at this package (relative or absolute, both accepted) |
| `symlink-foreign` | points somewhere else — another install owns it |
| `real-dir` | **drift.** Nothing in the current system creates one |

`real-dir` and `symlink-foreign` are what `driftedSkills()` reports and what the
SessionStart hook warns about.

## Escape hatches

| Variable | Effect |
|---|---|
| `PERSISTENT_PLANNING_SKIP_LINK=1` | no linking at all (runtime convention) |
| `PERSISTENT_PLANNING_NO_RECLAIM=1` | link, but never move an existing directory aside |

`updatePolicy: off` in `.claude/persistent-planning.json` suppresses the warning and
the automatic repair.

## Related

- [Plugin update delivery](../procedures/plugin-update-delivery.md)
- [Skill version marker](../reference/skill-version-marker.md)
- [Stale skill directory](../troubleshooting/stale-skill-dir-drift.md)
