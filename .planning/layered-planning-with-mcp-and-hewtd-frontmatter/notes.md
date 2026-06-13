# Notes: Layered Planning With MCP And HEWTD Frontmatter

## Key Findings

- HEWTD's frontmatter schema is a **22-field zod-validated standard** (`hit-em-with-the-docs/dist/action/core/metadata/schema.d.ts`). Six required: `title, tier, domains, status, last_updated, version`. Adopting it for plans gives us free interop with sidekick's typed fields.
- `semantic-sidekick`'s indexer (`src/core/indexer.ts:88-104`) already surfaces `load_priority, status, tier, domains, purpose, related_docs, last_updated` for filter/boost. Means HEWTD-shaped plans become searchable in sidekick with zero sidekick code change.
- `semantic-sidekick` is a fork of `semantic-pages` 0.10.0; both hardcode `**/*.md` as their glob (`indexer.ts:27`). Neither indexes code today. `semantic-pages`'s "documentation" framing refers to a `.documentation` companion mode (a second read-only MCP for hit-em-with-the-docs), not code-aware indexing.
- `JimmyMcBride/brain` and `JimmyMcBride/plan` are sibling Go CLIs that explicitly avoid overlap (brain = sessions/memory, plan = brainstorm→spec→ephemeral slices). Both ship multi-agent skill installers.
- Sidekick follows symlinks (`indexer.ts:30`), so symlinking `.planning/` into `.claude/.vault/` is the cheapest integration path.

## Research Sources

- `~/workspace/the-glitch-kingdom/hit-em-with-the-docs/dist/action/core/metadata/schema.d.ts` — HEWTD schema
- `~/workspace/the-glitch-kingdom/semantic-sidekick/src/core/indexer.ts` — sidekick frontmatter handling
- `~/workspace/the-glitch-kingdom/semantic-pages/src/core/indexer.ts` — pages glob and chunking
- `/tmp/brain-research/` — brain repo clone (analyzed via subagent)
- `/tmp/plan-research/` — plan repo clone (analyzed via subagent)

## Synthesized Findings

### Frontmatter alignment math
HEWTD-required fields fit plan artifacts cleanly except two:
- `tier` enum has no `plan` value → propose adding it.
- `version` doesn't naturally apply to a task plan → propose conditional optional via zod `.refine()`.
All other required fields (`title, domains, status, last_updated`) and the most-useful optional fields (`purpose, related_docs, load_priority, audience, tags, author, maintainer, implementation_status`) map cleanly.

### Why dedicated MCP wins over filesystem-only for subagent access
Filesystem-only relies on path conventions + grep — subagents have to know the layout, parse frontmatter themselves, handle stale reads. MCP gives:
- Structured JSON returns (no markdown parsing in the subagent)
- Atomic status mutations (no race condition on `status: ready → in_progress` if two agents grab the same file)
- Composable verbs (`next_atom(task)` is one call vs. "list, parse, sort, pick first ready")
- Future-proof: when we want to add planning-context bundles or graph traversal, MCP gives us the surface

### Why sequential atoms (not parallel queue)
Single-thread coding agent is the dominant case. Parallel atoms invite:
- Filesystem race conditions on claim
- Implicit dependency ordering bugs (atom B reads what atom A produced)
- Coordination overhead (which subagent owns what)
Sequential keeps the model simple and matches reality. Can revisit when we have a concrete parallel-agent workload.

### Why HEWTD schema change is non-breaking
- Adding an enum value (`tier: "plan"`) is additive — existing docs with `tier: "guide"` etc. still validate.
- Making `version` conditionally optional is additive — existing docs that always supply version still validate.
- Bump version 2.1.1 → 2.2.0 (minor).

### Layered model rationale
| Layer | Why exist | Without it |
|---|---|---|
| Initiative | Multi-task strategic boundary | Tasks orphaned, no cross-task context |
| Task | Bounded deliverable, current sm unit | (this is what we have) |
| Atom | Subagent hand-off unit | Subagents reconstruct from prose; lossy |
| Notes | Cross-cutting research | Bloats task_plan.md |

Atoms are the load-bearing addition. Without them, "subagent-accessible" means "subagent reads markdown and guesses what to do." Atoms make the contract explicit.

## Decisions Made

- HEWTD-aligned frontmatter for all plan artifacts in lg mode: Sidekick interop for free; single source of truth.
- `tier: "plan"` extension to HEWTD: Semantic clarity over reusing `reference`.
- Auto-detect mode via 90-day git author count, with printed decision banner: Friction-free for solo, structured for teams; banner avoids "magic" complaint.
- Sequential hand-off atoms: Matches single-agent reality; eliminates race conditions; can revisit.
- Dedicated planning MCP server: User-stated requirement; structured access beats path-convention parsing.
- Symlink for sidekick interop: Zero sidekick code change for v1.
- Defer drift detection / `semantic-codebase`: Independent large effort; not blocking.

## Errors & Solutions

- *(none yet)*

---

## Append-Only Log

### 2026-05-07 — Planning kickoff
- User confirmed: dedicated planning MCP (option C in subagent-access question)
- User confirmed: sequential hand-off atoms (option A in atom-semantics question)
- User confirmed earlier: auto-detect sm/lg via team size (with my caveat about surprise factor → mitigated with printed decision banner)
- Researched: brain (Go CLI, sessions+memory, no decomposition), plan (Go CLI, brainstorm→spec→slices, no memory), semantic-sidekick (markdown vault MCP, fork of semantic-pages), HEWTD schema (22-field zod), semantic-pages (markdown indexer with `.documentation` companion mode, NOT a code indexer)
- Settled scope: drift detection / `semantic-codebase` deferred — current effort is layered planning + MCP + HEWTD alignment
- Surfaced 7 open questions before implementation can begin (see task_plan.md → Key Questions)
- Created this planning structure as the meta-plan for the work
