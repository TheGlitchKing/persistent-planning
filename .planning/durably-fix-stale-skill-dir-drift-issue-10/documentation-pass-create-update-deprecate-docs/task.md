---
title: Documentation pass create update deprecate docs
tier: plan
domains:
  - planning
status: ready
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

- [ ] `.documentation/troubleshooting/stale-skill-dir-drift.md` -- the runbook. Symptom (plans missing Phase 5/6 and `## On Completion`), how to detect it (`diff` the linked script against the package, **not** a keyword grep), how to fix it (`relink`, or wait for the SessionStart migration), and where the `.bak-*` directory goes. Currently `.documentation/troubleshooting/` holds only INDEX/REGISTRY -- this is its first real doc
- [ ] `.documentation/architecture/skill-linking-and-reclaim.md` -- how `linkSkills()` works, the symlink-vs-real-dir decision, why reclaim renames instead of deleting, and the `<prefix>_SKIP_LINK` / `<prefix>_NO_RECLAIM` escape hatches
- [ ] `.documentation/reference/skill-version-marker.md` -- the `.version` file contract: who writes it, where it sits, precedence inside `installedVersion()`, and why it is not a `package.json`. Belongs in the custom `reference` domain registered in `.claude/hit-em-with-the-docs.json`
- [ ] `.documentation/procedures/plugin-update-delivery.md` -- the two distribution paths and what actually executes on each. Must state plainly that a marketplace install has no `node_modules` in the plugin cache, never runs npm postinstall, and resolves the runtime from `~/.claude/plugins/npm-cache/` -- so SessionStart is the only universal delivery point
- [ ] Register each new doc with `npx hewtd integrate <file> -a` -- markdown created outside that flow is not indexed, link-checked, or validated

### Update

- [ ] `CLAUDE.md` -- extend the release checklist: the runtime dependency range is a fourth coupled version site alongside the three that must already match
- [ ] `.documentation/testing/test-suite.md` -- document the marketplace-shaped fixture and the assert-by-diff rule
- [ ] `.documentation/architecture/lg-mode.md` -- cross-link the linking/reclaim doc where it describes how skills reach a consumer
- [ ] `CHANGELOG.md` -- an entry for the release, per the release checklist
- [ ] `README.md` -- only if user-facing install or repair guidance actually changes; skip otherwise rather than padding

### Deprecate / retire

- [ ] Audit for docs that describe the pre-reclaim skip behavior as correct; retire with `npx hewtd archive <file>`, never by deleting
- [ ] Confirm nothing still documents `relink` as the remedy for a real-directory skill dir -- that guidance is wrong until task 1 ships and incomplete after it

### Verify

- [ ] `npx hewtd maintain --quick` to regenerate indexes and check links
- [ ] `npx hewtd audit` for drift and policy violations; resolve what it reports
- [ ] Confirm every new doc is reachable from its domain INDEX and appears in REGISTRY
- [ ] Never hand-edit `INDEX.md` / `REGISTRY.md` -- they are generated, a PreToolUse hook denies it, and the next `hewtd index` overwrites it anyway
- [ ] Close the loop on issue #10 with a pointer to the runbook

## Decisions Made

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
**Currently ready** -- MANDATORY, last. Blocked on validation.

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
