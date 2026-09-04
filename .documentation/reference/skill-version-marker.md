---
title: Skill version marker (`.version`)
tier: reference
domains:
  - reference
audience:
  - developers
tags: []
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: >-
  Contract for the .version marker written beside SKILL.md — who writes it, when it
  is deliberately not written, and why it is the secondary drift signal.
estimated_read_time: 2 minutes
word_count: 295
last_validated: '2026-09-04'
backlinks: []
---

# Skill version marker (`.version`)

A one-line file beside `SKILL.md` recording which package version a linked skill came
from. Written by `scripts/link-skills.js`, read by `scripts/lib/skill-link.js`.

```
.claude/skills/persistent-planning/.version   ->   "3.2.0\n"
```

## Contract

| | |
|---|---|
| **Path** | `.claude/skills/<skill-name>/.version` |
| **Contents** | the package's `version`, plus a trailing newline |
| **Written by** | `writeVersionMarkers()`, after the linker runs |
| **Read by** | `readSkillVersion(consumerRoot, name)` — returns the string, or `null` |
| **Written when** | the skill resolves to `symlink-ok` |
| **Never written when** | the destination is a real directory |
| **Absent means** | unknown — never "current" |

## Why only healthy symlinks are stamped

Stamping a real directory would write "3.2.0" into a frozen pre-3.1.0 copy and mark
stale code as current — defeating the check it exists to support. A real directory is
left unstamped precisely so it reads as unknown.

Because a healthy skill dir is a symlink into the package, the marker written through
it lands in the package and is correct for free.

## Why not `package.json`

A `package.json` inside a skill directory invites npm to treat that directory as a
package and changes module resolution underneath it. A plain `.version` file cannot.
`skills/*/.version` is gitignored so a local install cannot commit a stray marker.

## This is the secondary signal

The **primary** drift signal is structural: is `.claude/skills/<name>` a symlink into
this package? A real directory is always drift, because nothing in the current system
creates one. That check needs no marker and cannot itself go stale.

The marker answers the follow-up question — *how far behind is it* — and is the only
signal available on install shapes where a symlink is impossible (Windows without
developer mode, some CI checkouts). Treat a missing marker as unknown, never as fine.

## Related

- [Skill linking and reclaim](../architecture/skill-linking-and-reclaim.md)
- [Stale skill directory](../troubleshooting/stale-skill-dir-drift.md)
