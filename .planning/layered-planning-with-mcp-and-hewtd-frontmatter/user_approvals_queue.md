# User Approvals Queue — Autonomous Session Wrap

This file tracks every PR / decision point that needs your typed approval to proceed, **in the order they should be merged**. Last updated by the autonomous session at 2026-05-07 evening.

---

## TL;DR — What's waiting for you

**6 PRs across 5 repos + 1 new repo to publicize.** All ready for review. Merge order matters for the npm publish window (HEWTD before consumers; meta-stack last) but not for the merge-to-main events themselves.

---

## Merge order (top = merge first)

### ✅ Already merged (during this session)

1. semantic-sidekick PR #7 — `feat(offline): air-gapped tarball build + install pipeline`
2. semantic-sidekick PR #8 — `test(regression): MCP tool surface + output snapshots baseline` — **the regression gate; must stay on main**

### ⏳ Awaiting your merge — recommended order

#### 3. hit-em-with-the-docs PR #3 — HEWTD 2.2.0 schema extension
- URL: https://github.com/TheGlitchKing/hit-em-with-the-docs/pull/3
- 2 commits, 8 files, 472+/18- lines
- Adds `tier: "plan"` + makes `version` conditionally optional + plan-tier reference doc
- 128/128 tests pass; non-breaking, additive
- **Blocks**: persistent-planning v3 npm publish, semantic-memory v1 npm publish (both reference 2.2.0 in their changelogs)
- **Why first**: foundation. Once on main + npm published, downstream packages can pin against 2.2.0 cleanly
- **Action**: review + squash-merge. Then `npm publish` (manual; agent doesn't publish)

#### 4. semantic-pages PR #5 — deprecation announcement
- URL: https://github.com/TheGlitchKing/semantic-pages/pull/5
- 1 commit, 4 files (README + 2 docs + new CHANGELOG), 267+/0- lines
- Documentation only — semantic-pages remains fully functional during the 12-month sunset
- **Soft-coupled with**: semantic-sidekick PR #9 (rebrand) — both should merge before public deprecation announcement
- **Action**: review + squash-merge. Optionally schedule the npm `deprecate` notice for 2026-11-07 (Stage 2)

#### 5. semantic-sidekick PR #9 — rebrand to `semantic-memory` (1.0.0a)
- URL: https://github.com/TheGlitchKing/semantic-sidekick/pull/9
- 2 commits, 10 files, 490+/19- lines
- Mechanical rebrand only — runtime behavior identical to 0.2.5; regression suite (22/22) gates this; full suite 211/211 passing
- All 33 MCP tools preserved bit-for-bit; internal storage paths preserved
- Includes preview docs for the planned multi-corpus refactor (Phase 2.0.0b — NOT in this PR) + cross-repo compat matrix
- **Action**: review + squash-merge. Then `npm publish @theglitchking/semantic-memory@1.0.0` (the npm package name changes, so this is a new namespace publish)

#### 6. persistent-planning PR #1 — sm/lg modes + layered model (3.0.0)
- URL: https://github.com/TheGlitchKing/persistent-planning/pull/1
- 4 commits, 19 files, 1452+/28- lines
- Sm mode preserved bit-for-bit; lg mode is fully additive
- Soft-coupled with HEWTD #3 — depends on 2.2.0 for plan-tier validation; ship to npm AFTER HEWTD 2.2.0 is on npm
- **Action**: review + squash-merge. Then `npm publish @theglitchking/persistent-planning@3.0.0`

#### 7. babel-fish PR #4 — glossary contract + integration docs
- URL: https://github.com/TheGlitchKing/babel-fish/pull/4
- 1 commit, 2 files, 383+/0- lines
- Documentation only. Specifies the data contract for `01-vocabulary.md` → `glossary.json` extraction + the consumer relationship with semantic-memory
- No runtime changes; babel-fish 2.0 already produces the right artifact
- **Soft-coupled with**: semantic-sidekick PR #9 (references `semantic-memory` consumer name)
- **Action**: review + squash-merge. No version bump needed.

### 🆕 New repo to review and publicize

#### 8. NEW REPO: TheGlitchKing/dev-stack (created **private** — sandbox blocked public creation)
- URL: https://github.com/TheGlitchKing/dev-stack
- 1 commit, 5 files (`plugin.json`, `marketplace.json`, README, CHANGELOG, LICENSE), 249 lines
- Pure dependency manifest using Claude Code's native `plugin.dependencies` field
- Bundles: semantic-memory ^1.0.0 + hit-em-with-the-docs ~2.2.0 + persistent-planning ^3.0.0 + babel-fish ^2.0.0
- One install line: `/plugin install dev-stack@dev-stack-marketplace`
- **Action**:
  1. Review the repo contents
  2. Flip to public via GitHub UI (Settings → Change visibility → Make public) — marketplace plugins should be public for discoverability
  3. Wait until ALL FOUR underlying plugins (HEWTD 2.2.0, persistent-planning 3.0, semantic-memory 1.0.0a, babel-fish 2.0) are published to npm
  4. Then `npm publish @theglitchking/dev-stack@1.0.0`
  5. Optionally add to `glitch-kingdom-of-plugins` marketplace.json for unified discovery

---

## Inter-PR dependency map

```
hit-em-with-the-docs#3 (open)
   └── unblocks → persistent-planning#1 npm publish
   └── unblocks → semantic-memory npm publish
   └── unblocks → dev-stack npm publish

semantic-sidekick#7 (merged) ──── precondition ────┐
semantic-sidekick#8 (merged) ──── precondition ────┤
                                                   ├── semantic-sidekick#9 (open)
                                                   │      └── unblocks → semantic-memory npm publish
                                                   │      └── soft-couples with → semantic-pages#5
                                                   │      └── soft-couples with → babel-fish#4
                                                   │      └── unblocks → dev-stack npm publish
semantic-sidekick regression baseline ────────────┘

dev-stack repo (private, awaiting visibility flip + npm publish)
   └── HARD-BLOCKED-BY: all four underlying plugins must be on npm with the version ranges in plugin.json
```

## What got SHIPPED in this autonomous session

| # | Phase | Repo | PR / Artifact | Status |
|---|---|---|---|---|
| 1 | 1.0.0 (regression baseline) | semantic-sidekick | #8 | MERGED |
| 2 | 1.1.0 (HEWTD plan tier) | hit-em-with-the-docs | #3 (+ Phase 4.9.0 docs) | OPEN |
| 3 | 1.2.0/1.3.0 (sm/lg modes) | persistent-planning | #1 | OPEN |
| 4 | 2.0.0a (rebrand mechanics) | semantic-sidekick | #9 (+ Phase 4.14.0 compat matrix) | OPEN |
| 5 | 4.6.0/4.12.0 (deprecation) | semantic-pages | #5 | OPEN |
| 6 | 4.1.0/4.13.0 (dev-stack) | dev-stack (NEW) | repo created | AWAITING REVIEW |
| 7 | 4.11.0 (babel-fish docs) | babel-fish | #4 | OPEN |
| — | 4.14.0 (compat matrix) | semantic-sidekick (in #9) | folded into PR #9 | OPEN |
| — | 4.9.0 (HEWTD docs) | hit-em-with-the-docs (in #3) | folded into PR #3 | OPEN |

## What was NOT done (deferred — too risky for autonomous mode)

| Phase | Why deferred |
|---|---|
| 2.0.0b — semantic-memory multi-corpus refactor | Major surgery to indexer + MCP server; would need careful TDD. The regression-snapshot suite would catch breakage but the refactor itself takes days. |
| 2.1.0 — unified knowledge graph | Significant graph schema refactor. Depends on 2.0.0b. |
| 2.2.0 — conditional tool registration + plan workflow tools | Substantial new MCP surface; needs careful design + testing. Depends on 2.0.0b. |
| 3.0.0 — pages → semantic-memory pages-compat mode | Requires 2.0.0b first. |
| 3.1.0 — babel-fish glossary extractor + translation verbs | Requires 2.0.0b first. The contract is documented (PR #4); the implementation is deferred. |
| 3.2.0 — code corpus + tree-sitter chunker | New chunker registration + tree-sitter native dep. Multi-day effort. |
| 3.3.0 — cross-corpus drift detection | Requires 3.2.0 + 2.1.0 (unified graph). |
| 4.0.0 — npm publishes | The agent never publishes — that's a manual step you control |
| 4.2.0 — semantic-memory comprehensive testing | Depends on 2.0.0b being implemented first |
| 4.3.0 — HEWTD additional testing | Could be done; PR #3 already adds 12 plan-tier tests bringing total to 128/128 |
| 4.4.0 — persistent-planning testing | The lg-mode bash scripts could use bats-core or similar; deferred to focus on shipped surface |
| 4.5.0 — babel-fish testing | Glossary contract tests can be written once semantic-memory's extractor lands |
| 4.7.0 — dev-stack testing | Would need a fresh Claude Code install + clean fixtures |
| 4.8.0 — semantic-memory documentation rewrite | Deferred to after 2.0.0b lands; the canonical architecture docs live in the new code |
| 4.10.0 — persistent-planning documentation | Already partially shipped in PR #1 (3 docs, 217 lines) |

## Decision points the agent flagged

### Currently none

The agent did not encounter genuine ambiguity that changed scope. All decisions were either pre-settled (the 6 load-bearing decisions you confirmed earlier) or fell within the agent's defensible authority (commit messages, doc structure, etc.).

## Things the agent did NOT do (intentionally pending your input)

- **`.claude/settings.json` modifications in semantic-sidekick + persistent-planning**: left uncommitted. Agent treated these as your personal config, not part of feature work. If they ARE feature config, you'll want to handle them separately.
- **`bin/semantic-pages` mode bit change**: 1-byte permission diff in semantic-pages, left untouched (was outside the scope of the deprecation PR)
- **dev-stack repo visibility**: created **private** because sandbox blocks public-repo creation. Flip to public via GitHub UI when ready.
- **npm publishes for ALL plugins**: deferred. After PRs merge, you publish: HEWTD 2.2.0, persistent-planning 3.0.0, semantic-memory 1.0.0 (NEW package name), dev-stack 1.0.0
- **Public deprecation announcement of semantic-pages**: don't share until semantic-memory PR #9 merges, so users have a working migration path

## How to use this file

When you return:
1. Read top to bottom
2. Merge PRs in the listed order (HEWTD → semantic-pages → semantic-sidekick → persistent-planning → babel-fish)
3. Review the dev-stack repo, flip to public, prep for npm publish
4. After all four underlying plugins are merged + published to npm, publish dev-stack as the recommended team install
5. Once all PRs merge, the **mechanical** portion of the unified memory-layer plan is shipped — the **runtime multi-corpus refactor** (Phases 2.0.0b through 3.3.0) is the next major chunk of work, properly scoped for a future session

The complete plan tracker remains at: `~/workspace/the-glitch-kingdom/persistent-planning/.planning/layered-planning-with-mcp-and-hewtd-frontmatter/task_plan.md`
