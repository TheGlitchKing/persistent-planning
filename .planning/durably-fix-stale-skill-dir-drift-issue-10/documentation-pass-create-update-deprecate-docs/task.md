---
title: Documentation pass create update deprecate docs
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: [validate-success-through-comprehensive-testing]
parallelizable: false
---

# Task: Documentation pass create update deprecate docs

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
Every artifact, behavior, and operational procedure this phase introduces is documented in `.documentation/` -- what it is, where it lives, how it works, how to fix it, why it matters -- and the indexes are regenerated.

## Atoms

### Create

- [x] `.documentation/troubleshooting/stale-skill-dir-drift.md` -- the runbook. Symptom (plans missing Phase 5/6 and `## On Completion`), how to detect it (`diff` the linked script against the package, **not** a keyword grep), how to fix it (`relink`, or wait for the SessionStart migration), and where the `.bak-*` directory goes. Currently `.documentation/troubleshooting/` holds only INDEX/REGISTRY -- this is its first real doc
- [x] `.documentation/architecture/skill-linking-and-reclaim.md` -- how `linkSkills()` works, the symlink-vs-real-dir decision, why reclaim renames instead of deleting, and the `<prefix>_SKIP_LINK` / `<prefix>_NO_RECLAIM` escape hatches
- [x] `.documentation/reference/skill-version-marker.md` -- the `.version` file contract: who writes it, where it sits, precedence inside `installedVersion()`, and why it is not a `package.json`. Belongs in the custom `reference` domain registered in `.claude/hit-em-with-the-docs.json`
- [x] `.documentation/procedures/plugin-update-delivery.md` -- the two distribution paths and what actually executes on each. Must state plainly that a marketplace install has no `node_modules` in the plugin cache, never runs npm postinstall, and resolves the runtime from `~/.claude/plugins/npm-cache/` -- so SessionStart is the only universal delivery point
- [x] Register each new doc with `npx hewtd integrate <file> -a` -- markdown created outside that flow is not indexed, link-checked, or validated

### Update

- [x] `CLAUDE.md` -- extend the release checklist: the runtime dependency range is a fourth coupled version site alongside the three that must already match
- [x] `.documentation/testing/test-suite.md` -- document the marketplace-shaped fixture and the assert-by-diff rule
- [x] `.documentation/architecture/lg-mode.md` -- cross-link the linking/reclaim doc where it describes how skills reach a consumer
- [x] `CHANGELOG.md` -- an entry for the release, per the release checklist
- [x] `README.md` -- only if user-facing install or repair guidance actually changes; skip otherwise rather than padding

### Deprecate / retire

- [x] Audited for docs describing the pre-reclaim skip as correct — **none exist**; the behavior was never documented, which is part of why it went unnoticed. Nothing to archive.
- [x] Confirmed nothing documented `relink` as the remedy for a real-dir skill dir; the new troubleshooting doc is the first place that guidance exists, and it is now correct

### Verify

- [x] `npx hewtd maintain --quick` to regenerate indexes and check links
- [x] `npx hewtd audit` for drift and policy violations; resolve what it reports
- [x] Confirm every new doc is reachable from its domain INDEX and appears in REGISTRY
- [x] Never hand-edit `INDEX.md` / `REGISTRY.md` -- they are generated, a PreToolUse hook denies it, and the next `hewtd index` overwrites it anyway
- [x] Close the loop on issue #10 with a pointer to the runbook

## Decisions Made

**Result: 4 created, 5 updated, 0 archived. Health 81.8 -> 94.5, 0 errors.**

Created (all via `hewtd integrate -a`, frontmatter corrected to `status: active` with
real `tier`/`audience`/`purpose`):
`troubleshooting/stale-skill-dir-drift.md`, `architecture/skill-linking-and-reclaim.md`,
`reference/skill-version-marker.md`, `procedures/plugin-update-delivery.md`.

Updated: `CLAUDE.md` (skill-link paragraph + the runtime dep as a fourth coupled version
site + the postinstall-cannot-repair rule), `.documentation/testing/test-suite.md`
(marketplace fixture, assert-by-diff, parse-don't-substring),
`.documentation/architecture/lg-mode.md` (cross-link), `CHANGELOG.md` (3.2.0),
`.documentation/standards/mandatory-closing-phases.md` (Phase 6 wording).

Nothing archived — see the audit atom.

**One pre-existing warning left standing**: `.documentation/README.md` sits in the
documentation root rather than a domain folder. It predates this phase and moving the
tree's own README is not this PR's call.

**Template wording changed mid-pass at the user's direction**: Phase 6 now reads
"create/update/deprecate as many docs as needed to capture what was done, where it lives,
how to troubleshoot it, etc." and the hewtd clause is now "you **MUST** use it", with the
three commands named inline. Applied to `scripts/init-planning.sh` (sm),
`templates/lg/phase.md` (lg), and the `skills/persistent-planning/SKILL.md` copy that
documents them; `tests/run.sh` assertion widened to the stable prefix.

**Four new docs, not one.** The phase produces four genuinely separate things: an
operational runbook, an architectural mechanism, a data contract, and a delivery
procedure. Folding them into a single page would put the runbook -- the thing someone
reads at 3am with broken plans -- behind three sections of architecture.

**The runbook is the highest-value artifact here.** The five-month silence happened
because nobody could recognize the symptom. `.documentation/troubleshooting/` being
empty is part of that story.

**Write the delivery constraint down explicitly.** "A marketplace install never runs npm
postinstall" is the non-obvious fact that reshaped this whole plan. Undocumented, the next
fix gets shipped through postinstall again.

**hewtd owns the lifecycle.** Create with `integrate -a`, retire with `archive`,
regenerate with `maintain --quick`. Docs are never deleted.

## Status
**Currently done** -- 4 created, 5 updated, indexes regenerated, 0 audit errors.

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
