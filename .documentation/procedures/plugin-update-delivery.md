---
title: Plugin update delivery — what actually runs, and when
tier: guide
domains:
  - procedures
audience:
  - developers
tags:
  - migration
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: What actually executes on each of the two distribution paths, why a marketplace
  install never runs npm postinstall, and how to ship a fix that repairs existing installs.
estimated_read_time: 3 minutes
word_count: 539
last_validated: '2026-09-04'
backlinks: []
---

# Plugin update delivery — what actually runs, and when

This package ships down two paths. They execute **different code at different times**,
and a fix delivered through the wrong one reaches nobody. Read this before shipping any
change that has to repair or migrate an existing install.

## The two paths

| | npm package | Claude Code marketplace plugin |
|---|---|---|
| Installed at | `node_modules/@theglitchking/persistent-planning` | `~/.claude/plugins/cache/persistent-planning-marketplace/persistent-planning/<version>/` |
| Runs `postinstall`? | **yes** | **no** |
| `node_modules` present? | yes | **no — the plugin cache has none** |
| Runtime resolved from | local `node_modules` | shared `~/.claude/plugins/npm-cache/node_modules/` |
| Runs every session | SessionStart hook | SessionStart hook |

## The constraint

**A marketplace install never runs npm postinstall.**

So `runPostinstall()` — and therefore the skill linker, the reclaim, and the version
marker — never execute on a marketplace update. A repair wired only into postinstall
ships to npm consumers and silently misses every marketplace consumer.

That is not a corner case. In issue #10 the broken population *was* the marketplace
consumers, precisely because they were the ones postinstall could never reach.

`runPostinstall()` also returns `null` when `INIT_CWD` equals the package root
(dev-in-place), which is why this repo has no `.claude/skills/persistent-planning` of
its own.

## The rule

> **Anything that must reach an existing install goes through the SessionStart hook.**
> It is the only code that runs every session in both shapes.

`hooks/session-start.js` `autoRepair()` is the reference implementation:

- **Fast path first.** Two `lstat`s settle the common "nothing to do" case before any
  work happens. Never make a healthy install pay.
- **Once per plugin version.** Stamped as `repairedSkillsForVersion` in
  `.claude/persistent-planning.json`. Stamped *regardless of outcome*, so a repair that
  cannot succeed does not retry every session; a later release moves the version and
  gets one fresh attempt.
- **Policy-gated.** `auto` repairs, `nudge` warns only, `off` does nothing. A user who
  turned updates off did not consent to filesystem mutation.
- **Spawned, not imported.** The migration runs in a child process with a timeout, so a
  failure is contained.
- **Fails open.** Every path is wrapped. A broken migration must never cost someone
  their session start.
- **Never let a dependency be fatal.** Load the runtime with `await import()` in a
  try/catch. A static import makes an unresolvable dependency fatal for the whole hook,
  including the repair — the delivery path must survive what it is delivering a fix for
  (#18). Only the update check genuinely needs the runtime.
- **Stamp on success, never on failure.** Marking a version done after a failed attempt
  turns a transient problem into a permanent one: the repair never runs again, even once
  the cause is gone. Retrying costs one spawn per session while genuinely drifted.
- **One stdout write.** The runtime owns the single `SessionStart` JSON response and
  exposes no append hook; a second response line is invalid. Merge into the existing
  intercept.

## Release checklist addendum

The version appears in **three** places that must match — `package.json`,
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both `metadata.version`
and the plugin entry). See `CLAUDE.md`.

Two more things to verify for a migration release:

1. **The `files` array actually ships the new code.** v3.0.0 shipped broken because
   `scripts/` and `templates/` were missing from it. Check with `npm pack --dry-run` and
   grep the listing for the files you added.
2. **Test from a marketplace-shaped fixture** — no `node_modules`, no postinstall — not
   from `npm install`. A test that passes under `npm install` proves nothing about the
   population that is actually broken. `tests/run.sh` builds exactly this fixture.

If a fix depends on a new `@theglitchking/claude-plugin-runtime`, it needs a runtime
publish, a dependency-range bump here, and a coordinated rollout — marketplace consumers
resolve the runtime from a shared cache, not a vendored copy. Preferring a change that
keeps the runtime unchanged is usually worth real effort; the issue #10 reclaim is
deliberately ordered *before* the runtime's linker for that reason.

## Related

- [Skill linking and reclaim](../architecture/skill-linking-and-reclaim.md)
- [Stale skill directory](../troubleshooting/stale-skill-dir-drift.md)
