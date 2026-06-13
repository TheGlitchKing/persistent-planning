# Task Plan: Semantic Memory Layer (semantic-sidekick → semantic-memory rebrand + unified architecture)

## Goal
Rebrand `semantic-sidekick` to `semantic-memory` and evolve it into a unified memory-layer plugin with one MCP server, six typed corpora (vault, code, plans, docs, research, project-map), a unified cross-corpus knowledge graph, conditional tool registration, in-process drift detection, and bidirectional human↔code translation via babel-fish integration. `persistent-planning` becomes the authoring layer (templates, slash commands, sm/lg modes, no MCP). `semantic-codebase` is never created — code lives as a corpus inside semantic-memory. HEWTD gets a non-breaking schema extension first. Distribution unifies via a `dev-stack` meta-plugin using Claude Code's native plugin-dependency feature.

## Architecture
- **1 plugin**: `semantic-memory` (renamed from `semantic-sidekick`, version bump to 1.0.0)
- **1 MCP server**, registered under `semantic-memory` key (renamed from `semantic-vault`)
- **6 corpora**: `vault`, `code`, `plans`, `docs`, `research`, `project-map`
- **Smart-middle activation**: on first run, semantic-memory scans the project and auto-enables corpora based on detected presence (`.claude/.vault/` → vault, `src/` → code, `.planning/` → plans, `.documentation/` → docs, `.research/` → research, `.babel-fish/` → project-map). Banner prints what got enabled. User can override in `corpora.json`.
- **Per-corpus indexes**: HNSW vector + text/BM25 + node set in the unified graph
- **Unified knowledge graph** spans all active corpora; edges typed (`links_to`, `related_to`, `backlink`, `imports`, `calls`, `defines`, `mentions`)
- **Empty/missing index** → `{status: "no_index", results: []}`, never errors
- **Conditional tool registration**:
  - Search verbs always register (per null-return contract)
  - Workflow verbs (`next_atom`, `update_atom_status`) register only when `plans` corpus active
  - Drift verbs register only when `code` + at least one doc-bearing corpus active
  - Translation verbs (`translate`, `reverse_translate`, `list_vocabulary`) register only when `project-map` corpus active AND `glossary.json` present
- **Config**: `.semantic/corpora.json`
- **Distribution**: federated plugins (each independently versioned and ownable) + `@theglitchking/dev-stack` meta-plugin using Claude Code's native `dependencies:` field for one-line team install + single version pin

## Scope at a glance
Six repos touched (in dependency order):
- `hit-em-with-the-docs` — schema extension (1.1.0); per-repo testing (4.3.0); per-repo documentation (4.9.0)
- `persistent-planning` — sm/lg modes, layered templates, slash commands; **no MCP** (1.2.0, 1.3.0); per-repo testing (4.4.0); per-repo documentation (4.10.0)
- `semantic-memory` (was `semantic-sidekick`) — full architectural refactor (2.x, 3.x); per-repo testing (4.2.0); per-repo documentation (4.8.0, canonical architecture docs)
- `babel-fish` — glossary contract + pre-commit hook integration (3.1.0 cooperates with semantic-memory); per-repo testing (4.5.0); per-repo documentation (4.11.0)
- `semantic-pages` — formal deprecation + migration tool (3.0.0); per-repo testing (4.6.0); per-repo documentation (4.12.0)
- `dev-stack` (NEW) — meta-plugin for unified distribution (4.1.0); per-repo testing (4.7.0); per-repo documentation (4.13.0)

End-state: **one MCP** (`semantic-memory`). `semantic-pages` enters formal deprecation. `semantic-codebase` is never created.

---

## Phases

Vocabulary used throughout this plan and in persistent-planning lg-mode templates:
- **Phase** (top, e.g. "1.0.0 — Foundation"): strategic grouping of related tasks; what other plans might call milestones
- **Task** (mid, e.g. "1.1.0: HEWTD schema extension"): bounded deliverable; unit of work assignable to a person or agent team
- **Atom** (lowest, the `- [ ]` checkboxes inside a task): subagent hand-off unit; the actionable atomic step. In lg-mode persistent-planning these become standalone files in `atoms/` for subagent access via MCP.
- **Notes** (cross-cutting): need-to-know references for plan implementation; not bound to a specific phase or task

**Default scheduling**: dependencies-first within a phase; tasks with no inter-dependencies are marked parallelizable so subagent teams can pick them up concurrently. Atoms within a task default to sequential (matches the sequential-hand-off decision; subagents process atoms in order).

### 1.0.0 — Foundation (sequential, blocks everything else)

#### 1.0.0: Regression-snapshot baseline (LOAD-BEARING — must precede any sidekick refactor)
- [ ] Capture golden snapshots of every existing semantic-sidekick MCP tool BEFORE any code changes: tool name, signature, example inputs, example return shape
- [ ] Snapshot existing `.claude/.vault/` workflows: representative reads (search_semantic, search_text, search_hybrid, backlinks, forwardlinks, graph_path, search_graph, get_stats), representative writes (create_note, update_note, update_frontmatter, delete_note, move_note)
- [ ] Performance baseline: query latency p50/p95 on representative vault, index size per chunk count
- [ ] Lock snapshots into CI as a regression gate
- [ ] Document the snapshot capture process in `docs/regression-snapshot.md`

#### 1.1.0: HEWTD 2.2.0 schema extension
- [ ] Add `"plan"` to `tier` enum in `src/.../metadata/schema.ts`
- [ ] Make `version` conditionally optional when `tier === "plan"` (zod `.refine()` or discriminated union)
- [ ] Update `REQUIRED_FIELDS` constant comment to note plan exception
- [ ] Tests: plan-tier validation (valid w/o version, valid w/ version, invalid w/ wrong tier)
- [ ] Release HEWTD 2.2.0 (minor, additive)

#### 1.2.0: persistent-planning sm/lg mode infrastructure (no MCP)
- [ ] Define `.planning/.meta/workspace.json` schema: `{schema_version, mode, auto_detected, detected_contributors, created_at}`
- [ ] Implement auto-detect heuristic in `init-planning.sh`: `git log --since="90 days ago" --format='%ae' | sort -u | wc -l` ≥ 2 → `lg`
- [ ] Add `--mode sm|lg` override flag to `/start-planning`
- [ ] Print decision banner so detection isn't surprising
- [ ] Sm mode = current behavior (regression baseline)
- [ ] Lg mode = creates `.planning/.meta/workspace.json`, uses layered templates, scaffolds plans corpus root for semantic-memory
- [ ] Backwards-compat: existing `.planning/<slug>/` folders without `.meta/` continue to work as sm

#### 1.3.0: persistent-planning layered model + HEWTD-compatible templates
- [ ] Four template variants under `templates/lg/`: `phase.md`, `task.md`, `atom.md`, `notes.md` (vocabulary: phase = top, task = mid, atom = subagent hand-off unit, notes = cross-cutting references)
- [ ] Each carries HEWTD-required frontmatter + `plan_kind` + `parent` fields
- [ ] Lifecycle status enums:
      - phase.status: `draft | active | paused | done | archived`
      - task.status: same enum, plus `parallelizable: bool` field for tasks with no inter-dependencies
      - atom.status: `ready | in_progress | done | blocked` (sequential hand-offs, no `claimed_by`)
- [ ] Directory shape: `.planning/<phase>/<task>/atoms/<atom>.md`. Standalone task = `.planning/<task>/`.
- [ ] `init-planning.sh` lg branches: `init phase`, `init task --parent <phase>`, `init atom --parent <task>`
- [ ] Three slash commands: `/start-planning` (phase), `/start-task`, `/start-atom`
- [ ] `archive/<phase-slug>/` move on phase status=archived
- [ ] **Subagent accessibility**: every layer (phase, task, atom, notes) is reachable via semantic-memory MCP verbs (defined in 2.2.0); subagents do not parse markdown — they call `read_phase`, `read_task`, `read_atom`, `next_atom`, `get_planning_context`
- [ ] **Default scheduling encoded in templates**: phase frontmatter declares the dependencies graph between its tasks (`depends_on: [task-slug, ...]`); planning MCP exposes `next_task(phase, exclude_in_progress)` that returns the next ready task respecting dependency order; tasks marked `parallelizable: true` can be returned in any order
- [ ] Anti-pattern doc: when to make an inline atom checkbox in a task_plan.md vs. spawn a standalone atom file (with examples)

---

### 2.0.0 — semantic-memory core (rebrand + multi-corpus + graph; sequential within)

#### 2.0.0: Rebrand + multi-corpus refactor
- [ ] Rename plugin: `semantic-sidekick` → `semantic-memory`
- [ ] Rename MCP key: `semantic-vault` → `semantic-memory`
- [ ] Update `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, npm package, README
- [ ] Define `.semantic/corpora.json` schema: `{corpora: [{name, root, glob, chunker, enabled}]}`
- [ ] Implement smart-middle first-run detection: scan project root for known markers, generate initial `corpora.json`, print banner of activated corpora
- [ ] Refactor indexer from single hardcoded vault → registry-driven N indexes
- [ ] Per-corpus directory: `.semantic/<corpus_name>/{INDEX, meta.json}`
- [ ] Pluggable chunker interface: `markdown` (existing), `tree-sitter-ts` (stub for 3.2.0), `fixed-window` (fallback)
- [ ] Per-corpus filter/boost respects HEWTD frontmatter (`load_priority`, `tier`, `status`, `domains`)
- [ ] Backwards-compat: legacy `.claude/.vault/` users get auto-default `corpora.json` pointing at the legacy path; no migration required for existing setups
- [ ] Search-tool surface: per-corpus verbs (`search_vault`, `search_code`, `search_plans`, `search_docs`, `search_research`, `search_project_map`) + `search_all(q)` — always registered, return `no_index` payload when corpus empty/missing
- [ ] Run regression suite from 1.0.0 — must pass

#### 2.1.0: Unified knowledge graph
- [ ] Refactor graph schema: nodes are `{corpus, doc_id, chunk_id?}`, edges typed
- [ ] Link extractors per chunker:
      - markdown: wikilinks `[[name]]`, frontmatter `related_docs:`, auto-derived `backlinks:`
      - tree-sitter (lands fully in 3.2.0): `imports`, `defines`, optionally `calls`
- [ ] Cross-corpus edge resolution at index time (e.g. `related_docs: ["src/auth/middleware.ts:requireAuth"]` → code symbol node)
- [ ] Update existing graph verbs (`search_graph`, `backlinks`, `forwardlinks`, `graph_path`) to be corpus-aware (return corpus tag with each node)
- [ ] Add `corpus_filter` option to graph traversal verbs
- [ ] Empty-corpus traversal: return node stub with `no_index` flag rather than skipping silently
- [ ] Run regression suite — must pass

#### 2.2.0: Conditional tool registration + plan workflow tools
- [ ] Tool registration scans `corpora.json` at startup; registers verb sets by category
- [ ] Plan workflow verbs (registered iff `plans` corpus active AND has data) — every layer is subagent-accessible via these verbs (subagents never parse markdown directly):
      - `list_phases(status?)`, `list_tasks(phase?, status?)`, `list_atoms(task?, status?)`
      - `read_phase(slug)`, `read_task(slug)`, `read_atom(slug)`, `read_notes(scope?)`
      - `next_task(phase, exclude_in_progress?)` — returns next ready task respecting `depends_on` graph; returns parallelizable tasks in any order
      - `next_atom(task)` — returns next `status: ready` atom in sequence (atoms within a task default to sequential)
      - `update_atom_status(slug, status)` — atomic frontmatter mutation (write-temp + fsync + rename)
      - `update_task_status(slug, status)` / `update_phase_status(slug, status)` — same atomic pattern
      - `get_planning_context(scope, slug)` — bundles parent chain + sibling status + relevant notes for one read; subagent's primary "load my context" verb
      - `append_notes(scope, slug, content)` — append-only writer for notes during plan implementation
- [ ] Atom reopen semantics: `done → in_progress` allowed; adds `reopened_at` audit field
- [ ] persistent-planning's slash commands shell into either these workflow verbs or the generic CRUD verbs already in semantic-memory
- [ ] Skill update: `SKILL.md` teaches subagents the workflow tool names, the layer vocabulary (phase/task/atom/notes), and the dependencies-first-then-parallelism scheduling default
- [ ] Run regression suite — must pass

---

### 3.0.0 — Ecosystem extensions (parallelizable across agent teams)

#### 3.0.0: pages → semantic-memory supersession (folds in `docs` corpus)
- [ ] `docs` corpus chunker = markdown with HEWTD-aware filter/boost (covers pages's documentation use case)
- [ ] `pages-compat` mode flag: disables capture/lint/synth/log layers, exposes only pages's original 21 tool names mapped to semantic-memory equivalents
- [ ] Companion `.documentation` mode: semantic-memory's reconcile.js learns to spawn a read-only secondary instance the way pages does today
- [ ] semantic-pages: README banner, npm `deprecate` notice, marketplace flag
- [ ] Migration tool: `semantic-pages-to-semantic-memory migrate` (vault paths, companion paths, generates `corpora.json`)
- [ ] Sunset window: 6 months from semantic-memory feature-completion → re-evaluate before pages removed
- [ ] Run regression suite (full + pages-compat tool surface) — must pass

#### 3.1.0: babel-fish integration (`project-map` corpus + glossary side-channel + translation verbs)
- [ ] Add `project-map` to corpus type registry; chunker = markdown for sections 02–19
- [ ] Implement glossary extractor: `01-vocabulary.md` → `glossary.json` (key→{path, section, confidence}) at index time
- [ ] Persist `glossary.json` alongside the corpus index under `.semantic/project-map/`
- [ ] Translation MCP verbs (registered iff `project-map` corpus active AND glossary present):
      - `translate(human_term, fuzzy?)` — exact + fuzzy match against glossary; returns canonical path with confidence
      - `reverse_translate(file_path)` — returns human term(s) referencing the path
      - `list_vocabulary(section_filter?)` — enumerates the glossary
- [ ] Optional query-rewriting hook (off by default; `corpora.json` flag `vocabulary_query_rewrite: true`):
      - semantic-memory search verbs preprocess the query through `translate()` and inline expansions before embedding
- [ ] Integration test: babel-fish generates project map → semantic-memory indexes → `translate("deals page")` returns deterministic mapping → `search_code` query expanded with mapping returns relevant code
- [ ] babel-fish-side: confirm pre-commit hook regeneration triggers semantic-memory reindex (or file-watcher catches it)
- [ ] Run regression suite — must pass

#### 3.2.0: Code corpus + tree-sitter chunker
- [ ] tree-sitter-typescript ingestion (TS/JS/TSX/JSX for v1; Python deferred)
- [ ] Symbol-aware chunking: function/class/method/interface boundaries; fixed-window fallback for unparseable regions
- [ ] Per-chunk metadata: `file_path, symbol_name, symbol_kind, language, line_start, line_end, content_hash`
- [ ] Code-specific tools (registered iff `code` corpus active):
      - `search_code(query, language?, symbol_kind?, pathGlob?)` — wired to multi-corpus search surface from 2.0.0
      - `read_symbol(file, symbol_name)`
      - `list_symbols(file|pathGlob)`
- [ ] `imports` + `defines` edges flow into unified graph (2.1.0). `calls` edges deferred for future minor.
- [ ] Run regression suite — must pass

#### 3.3.0: Cross-corpus drift detection (in-process, no shell-out)
- [ ] `detect_drift(scope?)` MCP tool — defaults to all docs/plans → code
- [ ] Algorithm uses unified graph + cross-corpus search:
      - For each edge `{plan|doc → code_symbol}`: resolve symbol, vector-compare claim text vs symbol code, structural diff (signature)
      - For each high-priority doc/plan chunk (HEWTD `load_priority` ≥ N): `search_code(chunk_text)`, inspect top hits
- [ ] Three signals: embedding similarity below threshold, signature mismatch, mtime gap
- [ ] Return per-claim `{spec_claim, matched_code: [{file, lines, similarity, structural_diff}], severity, suggested_action}` — no LLM judgment in tool itself
- [ ] Optional sink (off by default, `--sink` flag): write findings to vault `drift-findings/` via existing `create_note` tool
- [ ] Threshold config in `corpora.json` (similarity cutoff, mtime grace, severity rules; sensible defaults)
- [ ] Dogfood test: run against this repo's own lg-mode plans
- [ ] Run regression suite — must pass

---

### 4.0.0 — Distribution (sequential, after 1-3 stable)

#### 4.0.0: Per-plugin coordinated releases
- [ ] HEWTD 2.2.0 published (already shipped in 1.1.0; confirm dependency-bumps in consumers)
- [ ] persistent-planning 3.0.0: sm/lg modes, lg templates, no MCP, falls back to filesystem grep for plan reads when semantic-memory absent
- [ ] semantic-memory 1.0.0: full multi-corpus, unified graph, conditional tools, code corpus, drift, pages-compat, translation, smart-middle activation, rebranded
- [ ] CHANGELOG entries across all repos (HEWTD, persistent-planning, semantic-memory, semantic-pages final deprecation)
- [ ] semantic-pages final deprecation release with notice pointing to semantic-memory

#### 4.1.0: dev-stack meta-plugin
- [ ] New repo: `@theglitchking/dev-stack` under `glitch-kingdom-of-plugins/` so all referenced plugins live in the same marketplace (no `allowCrossMarketplaceDependenciesOn` needed)
- [ ] `plugin.json` declares dependencies with semver ranges:
      ```json
      {
        "dependencies": [
          { "name": "semantic-memory", "version": "^1.0.0" },
          { "name": "hit-em-with-the-docs", "version": "~2.2.0" },
          { "name": "persistent-planning", "version": "^3.0.0" },
          { "name": "babel-fish", "version": "^2.0.0" }
        ]
      }
      ```
- [ ] No commands, no skills, no MCP — pure dependency manifest
- [ ] List in `glitch-kingdom-of-plugins/marketplace.json` so `/plugin install dev-stack` resolves
- [ ] Verify resolution: `/plugin install dev-stack` on a clean install pulls all four plugins, no conflicts, MCP starts
- [ ] Test `claude plugin prune` cleanup behavior on dev-stack uninstall
- [ ] README: "the recommended install for teams adopting the full memory-layer stack" + cherry-pick instructions for individual plugins

#### 4.2.0: `semantic-memory` repo — comprehensive testing (formerly `semantic-sidekick`)
- [ ] **Per-chunker unit tests**: markdown chunker (frontmatter, wikilinks, related_docs), tree-sitter chunker (symbol boundaries, fallback, content_hash stability), fixed-window chunker
- [ ] **Per-corpus indexer unit tests**: empty corpus init, first-time index, incremental reindex, file deletion, file rename, HNSW persistence + crash-resume, HEWTD frontmatter integration
- [ ] **MCP tool unit tests** (every verb, every category):
      - search verbs (`search_<corpus>`, `search_all`) — populated and `no_index` cases
      - graph verbs (`backlinks`, `forwardlinks`, `graph_path`, `search_graph`) — same-corpus and cross-corpus
      - workflow verbs (`list_phases`, `list_tasks`, `list_atoms`, `read_phase`, `read_task`, `read_atom`, `read_notes`, `next_task`, `next_atom`, `update_atom_status`, `update_task_status`, `update_phase_status`, `get_planning_context`, `append_notes`) — registered/unregistered behavior
      - drift verbs — populated and missing-corpus paths
      - translation verbs (`translate`, `reverse_translate`, `list_vocabulary`) — exact, fuzzy, missing glossary, query-rewriting on/off
      - CRUD verbs (`create_note`, `update_note`, `delete_note`, `update_frontmatter`, `move_note`, `manage_tags`, `rename_tag`, `reindex`)
- [ ] **Integration tests — full corpus lifecycle**: create → index → search → update frontmatter → reindex → search reflects update → delete → search returns no_match
- [ ] **Integration tests — cross-corpus graph**: create plan with `related_docs: [src/foo.ts:bar]` → edge resolves → `graph_path` returns 1-hop → delete code symbol → edge marked stale
- [ ] **Integration tests — conditional tool registration**: boot vault-only → workflow/drift/translation verbs not registered. Enable plans → workflow verbs appear. Enable code + docs → drift verbs appear. Enable project-map with glossary → translation verbs appear.
- [ ] **Integration tests — empty/null contract**: search verbs always exist; missing corpus returns `no_index`. Graph traversal hitting unindexed corpus returns node stub with `no_index` flag. `search_all` skips empty corpora silently.
- [ ] **Integration tests — write atomicity**: `update_atom_status` under simulated mid-write crash leaves file consistent. Concurrent reads during write never see partial frontmatter.
- [ ] **Integration tests — smart-middle activation**: project with no markers → only `vault` enabled. Project with `.planning/` → `plans` auto-enabled. All six markers present → all six enabled, banner correct.
- [ ] **Regression tests — existing semantic-sidekick functionality (LOAD-BEARING)**:
      - replay golden snapshots from Phase 1.0.0 against the rebranded + refactored plugin
      - every existing tool re-tested with identical inputs → identical outputs (within embedding tolerance)
      - existing `.claude/.vault/` workflows continue to work without `corpora.json`
      - performance: post-refactor query latency on a vault-only setup within 10% of 1.0.0 baseline
      - any breaking change explicit, documented, signed off — no silent shifts
- [ ] **Regression tests — pages-compat**: `pages-compat` mode exposes the original 21 pages tools. `.documentation` companion mode spawns read-only secondary instance correctly.
- [ ] **Drift detection golden tests**: synthetic drift cases (signature change, removed symbol, mtime gap) → known-good severity output. False-positive resistance: synonymous-but-correct doc/code pairs do not flag drift.
- [ ] **Performance baselines** (capture, don't gate): index size per 10k chunks, query latency p50/p95 per corpus, graph traversal latency at 1/2/3 hops, reindex latency on no-op vs full rebuild
- [ ] **CI matrix**: Node 20 + Node 22; single corpus, all corpora, mixed populated/empty; coverage report gated >80% line coverage on semantic-memory core

#### 4.3.0: `hit-em-with-the-docs` repo — comprehensive testing
- [ ] **Schema validation matrix tests**: every tier × valid/missing required field; `tier: "plan"` × version-present + version-absent; reject invalid tier values with helpful error
- [ ] **Backwards-compat tests**: existing docs in HEWTD's own corpus (no `tier: "plan"`) still validate post-2.2.0
- [ ] **CLI integration tests**: `hewtd validate` accepts plan-tier docs; `hewtd fix` doesn't try to add `version:` when `tier: "plan"`
- [ ] **Round-trip test**: write plan-tier doc → validate → fix → revalidate (no-op) — confirms idempotency
- [ ] CI: regression suite must pass for HEWTD's own self-documentation corpus

#### 4.4.0: `persistent-planning` repo — comprehensive testing
- [ ] **sm-mode regression tests**: existing v2 single-task behavior preserved exactly; current `.planning/<slug>/task_plan.md` flow works unchanged
- [ ] **lg-mode unit tests**:
      - phase/task/atom/notes template rendering with HEWTD-required frontmatter
      - status transitions per layer (phase: draft→active→done; task: same; atom: ready→in_progress→done, plus reopen path with `reopened_at`)
      - directory layout creation (`<phase>/<task>/atoms/<atom>.md`)
      - `init phase`, `init task --parent <phase>`, `init atom --parent <task>` behaviors
- [ ] **Auto-detect heuristic tests**: mock `git log` outputs for 0/1/2/N contributors → expected mode + banner text
- [ ] **Mode override tests**: `--mode sm`/`--mode lg` flags stick (write to `workspace.json`); subsequent `/start-planning` doesn't re-evaluate
- [ ] **MCP-absent fallback tests**: when semantic-memory not installed, slash commands still create files correctly via filesystem (degraded mode, no structured reads)
- [ ] **MCP-present integration tests**: slash commands invoke semantic-memory's `create_note`/`update_frontmatter`/`next_atom` verbs and round-trip correctly
- [ ] **Dependency-resolution tests for `next_task()`**: tasks with `depends_on` only return when all deps are `done`; tasks with `parallelizable: true` return in any order
- [ ] **Migration tests**: existing v2 `.planning/<slug>/` → opening with v3 sm-mode works without `.meta/`; explicit `/start-planning --mode lg` migrates to lg layout

#### 4.5.0: `babel-fish` repo — comprehensive testing
- [ ] **Glossary contract tests**: `01-vocabulary.md` → `glossary.json` shape is stable across babel-fish versions (locked schema; bump = breaking change for semantic-memory consumer)
- [ ] **Pre-commit hook integration tests**: hook regenerates project map → semantic-memory file-watcher catches it OR explicit reindex trigger fires
- [ ] **End-to-end with semantic-memory**:
      - babel-fish runs in a test repo → generates 19 sections + glossary
      - semantic-memory indexes the output → `translate("deals page")` returns the canonical mapping
      - `search_code("deals page")` with `vocabulary_query_rewrite: true` finds the right code symbol
- [ ] **Regression tests for babel-fish 2.0 functionality**: nothing in this work breaks existing babel-fish standalone usage

#### 4.6.0: `semantic-pages` repo — deprecation-period testing
- [ ] **Deprecation banner display tests**: README banner renders, npm `deprecate` notice fires on install
- [ ] **Migration tool tests**: `semantic-pages-to-semantic-memory migrate` correctly translates vault paths, `.documentation` companion paths, generates valid `corpora.json`
- [ ] **Final-release regression tests**: pages's existing 21-tool surface still works in the final pre-removal release (users on the deprecation runway aren't broken)
- [ ] **Cross-plugin compat test**: pages and semantic-memory installed simultaneously → no MCP-key collision (semantic-memory uses `semantic-memory`, pages uses `semantic-vault` until removed)

#### 4.7.0: `dev-stack` repo — comprehensive testing
- [ ] **Install resolution tests**: clean Claude Code + `/plugin install dev-stack` → all four plugins (`semantic-memory`, `hewtd`, `persistent-planning`, `babel-fish`) installed, no version conflicts, MCP starts
- [ ] **Upgrade matrix tests**: `dev-stack@1.0.0 → 1.1.0` cleanly bumps each pinned dependency
- [ ] **Cherry-pick interop tests**: install one plugin standalone without dev-stack, then later install dev-stack → no double-install, version intersection works
- [ ] **`claude plugin prune` tests**: uninstalling dev-stack removes orphaned auto-installed deps (only those not also user-pinned)
- [ ] **Cross-marketplace tests** (if any underlying plugin moves to a different marketplace): `allowCrossMarketplaceDependenciesOn` flag honored
- [ ] **CI matrix**: clean install / upgrade / cherry-pick / prune across Claude Code versions ≥ supported floor

#### 4.8.0: `semantic-memory` repo — comprehensive documentation (canonical architecture docs live here)
- [ ] **README rewrite — "memory layer" framing**: opens with unified-MCP architecture diagram; quickstart for each corpus type; explicit "supersedes semantic-pages" callout; explicit "rebrand from semantic-sidekick" notice with migration link
- [ ] **`docs/architecture.md`**: design rationale (one MCP not N), unified knowledge graph (edge types, cross-corpus resolution, traversal), conditional tool registration matrix, the `no_index` contract
- [ ] **`docs/corpora.md`**: `corpora.json` schema reference, chunker registry, per-corpus tuning (HEWTD boosts, drift thresholds), adding a new corpus type, smart-middle activation semantics
- [ ] **`docs/mcp-reference.md`**: every MCP tool, signature, return shape, registration condition; examples per tool with realistic inputs
- [ ] **`docs/cookbook/`** — task-oriented guides:
      - `vault-only.md` (the legacy semantic-sidekick experience)
      - `with-planning.md` (semantic-memory + persistent-planning workflow)
      - `with-codebase.md` (code corpus + tree-sitter setup)
      - `with-babel-fish.md` (project-map + translation verbs)
      - `drift-detection.md` (cross-corpus drift quickstart)
      - `pages-migration.md` (cross-link from migration doc)
      - `rebrand-migration.md` (semantic-sidekick → semantic-memory for existing users)
- [ ] **`docs/skill-author-guide.md`**: how a federated plugin (HEWTD, persistent-planning, babel-fish) targets semantic-memory's MCP; the "authoring API" surface (`create_note`, `update_frontmatter`, etc.); the "side-channel" pattern (babel-fish glossary, plan workflow verbs); testing your skill against a semantic-memory test fixture
- [ ] **`docs/troubleshooting.md`**: "MCP didn't start" diagnostics; "search returns no_index" — expected vs broken; reindex from scratch; log locations and verbosity flags
- [ ] **`docs/architecture-decisions/`** (ADRs):
      - ADR-001: unified single-MCP architecture
      - ADR-002: unified knowledge graph spans corpora
      - ADR-003: `.md` is content SoT, indexes are retrieval/relationship SoT
      - ADR-004: federated plugins + dev-stack meta-package over monolith
      - ADR-005: `semantic-codebase` folded into semantic-memory rather than shipped separately
      - ADR-006: rebrand `semantic-sidekick` → `semantic-memory`
      - ADR-007: smart-middle corpus activation (auto-detect on first run)
      - ADR-008: babel-fish as first-class translation participant (corpus + side-channel + verbs)
- [ ] **HEWTD frontmatter on every doc page**: dogfood the `docs` corpus; every published doc validates against HEWTD 2.2.0
- [ ] **CHANGELOG.md** entry for 1.0.0 (rebrand + multi-corpus + everything)

#### 4.9.0: `hit-em-with-the-docs` repo — comprehensive documentation
- [ ] **README updates**: explain the new `tier: "plan"` value and when to use it; cross-reference persistent-planning as the primary plan-tier author
- [ ] **`docs/tier-reference.md`**: full enum reference; for each tier, when to use, what's required, examples
- [ ] **`docs/plan-tier-frontmatter.md`** (new): full schema for plan-tier docs (frontmatter fields, `version` exception); examples drawn from persistent-planning's lg-mode templates
- [ ] **CHANGELOG.md** entry for 2.2.0 (additive: new tier value + conditional version requirement)
- [ ] **Examples directory**: add at least one plan-tier example doc validated by the test suite

#### 4.10.0: `persistent-planning` repo — comprehensive documentation
- [ ] **README rewrite for v3.0.0**: opens with sm/lg distinction; explains layered model (phase/task/atom/notes) with diagram; explicitly states "no MCP — uses semantic-memory's MCP when present, falls back to filesystem when absent"
- [ ] **`docs/sm-mode.md`**: the simple single-task workflow; identical to v2 behavior; for solo use
- [ ] **`docs/lg-mode.md`**: phase/task/atom/notes hierarchy; HEWTD frontmatter on every layer; subagent-accessibility via semantic-memory MCP; dependencies-first-then-parallelism scheduling default
- [ ] **`docs/migration-2-to-3.md`**: how existing v2 plans behave under v3 sm-mode (zero changes); how to opt into lg-mode; explicit migration script if needed
- [ ] **`docs/integration-with-semantic-memory.md`**: how persistent-planning slash commands shell into semantic-memory's workflow verbs; how subagents read planning state via MCP; what degrades when semantic-memory is absent
- [ ] **`docs/scheduling.md`**: explanation of `depends_on:` and `parallelizable:` task fields; how `next_task()` walks the dep graph; subagent team optimization patterns
- [ ] **Anti-pattern doc**: when to make an inline atom checkbox vs. spawn a standalone atom file (with examples)
- [ ] **Skill (SKILL.md)** updates: teaches subagents the layer vocabulary, MCP verb names, scheduling defaults
- [ ] **CHANGELOG.md** entry for 3.0.0 (sm/lg modes, layered templates, MCP removal — major bump)

#### 4.11.0: `babel-fish` repo — comprehensive documentation
- [ ] **README updates**: explain the semantic-memory consumer relationship; "babel-fish writes, semantic-memory indexes + translates"; link to semantic-memory's `with-babel-fish` cookbook
- [ ] **`docs/glossary-contract.md`**: the `01-vocabulary.md` → `glossary.json` contract; field schema; versioning rules (any change is breaking for consumers)
- [ ] **`docs/translation-verbs.md`**: how downstream consumers (semantic-memory, custom skills) call `translate`/`reverse_translate`/`list_vocabulary`; example queries and responses
- [ ] **`docs/integration-with-semantic-memory.md`**: how the pre-commit hook triggers reindex; what `.semantic/project-map/` looks like after indexing; troubleshooting glossary parse failures
- [ ] **CHANGELOG.md** entry for whichever version bump captures the consumer-contract formalization

#### 4.12.0: `semantic-pages` repo — deprecation documentation
- [ ] **README banner**: prominent "DEPRECATED — use `semantic-memory`" with link to migration guide
- [ ] **`docs/migration-to-semantic-memory.md`**: step-by-step migration (install semantic-memory, run migrate tool, verify corpora.json, uninstall pages); FAQ for compat-mode users
- [ ] **`docs/sunset-timeline.md`**: when each removal stage happens (deprecation announce → npm deprecate → marketplace flag → final release → marketplace removal); current schedule + how to track
- [ ] **CHANGELOG.md** final entry (deprecation + pointer)

#### 4.13.0: `dev-stack` repo — comprehensive documentation
- [ ] **README**: "the recommended install for teams adopting the full memory-layer stack"; one-line install (`/plugin install dev-stack`); single version pin example; what's included; how to upgrade the matrix
- [ ] **`docs/cherry-pick-guide.md`**: when NOT to use dev-stack (you only want one underlying plugin); how to install plugins individually; how to migrate from cherry-pick to dev-stack later
- [ ] **`docs/upgrade-matrix.md`**: the current dependency matrix per dev-stack version; semver intersection rules; how to read resolution errors
- [ ] **`docs/release-notes/`** per dev-stack version: which underlying plugin versions changed and why
- [ ] **CHANGELOG.md** entry for 1.0.0

#### 4.14.0: Cross-repo coordination (final consolidation)
- [ ] **Cross-references confirmed**: persistent-planning README + HEWTD README + babel-fish README + dev-stack README all point at semantic-memory docs as the canonical architecture reference
- [ ] **Stack diagram lives in semantic-memory `docs/architecture.md`** and is referenced from each plugin's README
- [ ] **Versioning compatibility matrix published** at semantic-memory `docs/compat-matrix.md`: which combinations of HEWTD × persistent-planning × semantic-memory × babel-fish are tested together
- [ ] **Glossary of terms** in semantic-memory `docs/glossary.md`: phase/task/atom/notes vocabulary, corpus/chunker/index/graph distinction, producer/side-channel pattern — single canonical definition referenced from every other plugin's docs

---

## Decisions Made

### Architecture
- **Unified single-MCP architecture**: one plugin, one MCP, N corpora. Cross-corpus search and drift become in-process method calls. Reverses earlier "one MCP per corpus" thinking.
- **Unified knowledge graph spans corpora**: cross-corpus edges (e.g. plan → code symbol). Drift detection requires it; cheap when in-process.
- **`semantic-codebase` plugin never created**: folded into semantic-memory as `code` corpus. Shared embedder, in-process drift, simpler ecosystem.
- **persistent-planning loses its MCP**: workflow verbs migrate into semantic-memory under conditional registration on `plans` corpus. persistent-planning becomes pure authoring layer.
- **Embedder NOT extracted to shared package**: single plugin, single process — embedder lives inside semantic-memory.
- **`.md` is content SoT, semantic-memory MCP is retrieval/relationship SoT**: not "indexes win." Indexes are not stable persistence (model upgrades invalidate them); .md is git-trackable and survives. Co-authoritative by concern.
- **Tool registration conditional on active corpora**: workflow + drift + translation verbs only register when their required corpora are active. Search verbs always register and return `no_index` for empty corpora.
- **Sidekick existing functionality preserved bit-for-bit (LOAD-BEARING)**: refactor is strictly additive from user perspective. Enforced by golden-snapshot regression suite captured BEFORE any code changes (Phase 1.0.0).

### Branding & versioning
- **Rebrand `semantic-sidekick` → `semantic-memory`**: name now reflects the multi-corpus, multi-purpose memory layer it has become.
- **MCP key rename**: `semantic-vault` → `semantic-memory`. Affects every consumer's `.mcp.json`; documented in rebrand-migration cookbook.
- **Version bump to 1.0.0** alongside the rebrand: signals architectural inflection point honestly. Even though the surface is preserved, the scope of change earns the major bump.

### Corpora
- **6 corpora out of the box**: `vault`, `code`, `plans`, `docs`, `research`, `project-map` (babel-fish output with structured `glossary.json` side-channel)
- **Smart-middle activation**: on first run, semantic-memory scans the project root for known markers and auto-enables corpora based on detected presence. Banner prints what got enabled. User can override via `corpora.json`.
- **Per-corpus index location**: `.semantic/<corpus>/INDEX/` (per-corpus subdir) — gitignored. Cleaner inspection than namespaced shared dir.

### Frontmatter & schema
- **HEWTD-aligned frontmatter for plans**: sidekick already filters/boosts on the same field names. Adopting HEWTD = interop for zero indexer code change. Single source of truth.
- **`tier: "plan"` extension over reusing `reference`**: semantic clarity. "Plan" is its own artifact category.
- **HEWTD `version` field for plans**: absent (not auto-set, not required). Plans have lifecycle status; version doesn't apply.

### Workflow & lifecycle
- **Layer vocabulary**: phase (top, strategic grouping) → task (mid, bounded deliverable) → atom (lowest, subagent hand-off unit). Notes are cross-cutting references, not in the hierarchy. This vocabulary is consistent between this meta-plan and lg-mode persistent-planning templates.
- **Subagent accessibility for every layer**: phases, tasks, atoms, and notes are all reachable via semantic-memory MCP verbs (`read_phase`, `read_task`, `read_atom`, `read_notes`, `get_planning_context`, etc.). Subagents do not parse markdown directly — structured returns from the MCP are the contract.
- **Default scheduling: dependencies-first, then parallelism**: tasks within a phase declare `depends_on:` in frontmatter; planning MCP's `next_task(phase)` returns ready tasks respecting the dep graph. Tasks marked `parallelizable: true` (no inter-deps) can be returned in any order — subagent teams pick them up concurrently for optimization. Atoms within a task default to sequential (matches single-agent reality and the sequential hand-off decision).
- **Sm/lg auto-detected by 90-day git author count**: zero-friction for solo, structured for teams. Banner avoids "magic" complaint. Override respected.
- **Sequential hand-off atoms**: matches single-agent reality; eliminates race conditions; revisitable.
- **Atom reopen allowed (`done → in_progress`)** with `reopened_at` audit field.
- **Three slash commands** (`/start-planning` for phase, `/start-task`, `/start-atom`) over one parameterized command: cleaner discovery; matches the layer vocabulary.
- **Symlink (or `corpora.json` root override) for `.planning/` interop**: zero or near-zero semantic-memory code change.

### babel-fish integration
- **babel-fish is a first-class translation participant**: not just a producer. Three integration points: (1) `project-map` corpus for sections 02–19, (2) structured `glossary.json` extractor from `01-vocabulary.md`, (3) dedicated `translate` / `reverse_translate` / `list_vocabulary` MCP verbs.
- **Query-rewriting via babel-fish is opt-in** (`corpora.json` flag, default off): silent rewriting can confuse users debugging searches; trade-off documented.
- **babel-fish in v1 dev-stack matrix at `^2.0.0`**: producer + side-channel pattern earns first-class participation.

### pages supersession
- **semantic-memory supersedes pages long-term**: pages enters formal deprecation. semantic-memory gains `pages-compat` profile + `.documentation` companion-spawn behavior.
- **6-month sunset window** from semantic-memory feature-completion before pages removed from marketplace; re-evaluate based on download counts.
- **Automated migration tool**: `semantic-pages-to-semantic-memory migrate` (vault paths, companion paths, `corpora.json` scaffold).

### Distribution & sequencing
- **Federated plugins + `dev-stack` meta-plugin**: each plugin keeps independent repo, release cadence, and ownership; `dev-stack` uses Claude Code's native `dependencies:` field in `plugin.json` for one-line team install + single version pin. Gets install-ergonomics wins of monolithic without change-isolation costs.
- **Native plugin-dependency support confirmed**: Claude Code's `plugin.json` accepts `dependencies` with semver ranges, resolves recursively, intersects ranges across plugins, supports cross-marketplace via `allowCrossMarketplaceDependenciesOn`. No install scripts needed.
- **Sequencing: dependency-first, then parallelism within phase groups (LOAD-BEARING DEFAULT)**: 1.x (Foundation) must be fully sequential. 2.x (semantic-memory core) sequential within. 3.x (Ecosystem extensions) parallelizable across agent teams — each extension is independent and can be worked by a separate subagent. 4.x (Distribution) sequential. This dependency-first-then-parallelism rule is the default for both this plan AND for lg-mode persistent-planning (encoded in `task.depends_on:` frontmatter and surfaced via `next_task()` MCP verb).

### Producer plugin pattern
- **Federated producer model formalized**: babel-fish, persistent-planning, HEWTD all become "producer" plugins (skills + CLIs that author content into corpora). Some producers also expose **structured side-channels** (the babel-fish glossary, the persistent-planning workflow verbs) that warrant dedicated MCP verbs beyond generic search. Documented in skill author guide (4.3.0).

---

## Implementation Notes (soft questions, leans accepted as defaults — re-evaluate at phase time)

These are working assumptions that don't block work. They can be adjusted when the corresponding phase begins.

1. **Atom granularity guidance**: phase checkbox vs. spawn an atom — anti-pattern doc to be written during 1.3.0 with examples drawn from the lg-mode worked example.
2. **Auto-detect mode override persistence**: `--mode sm` sticks for that project (writes to `workspace.json`); each `/start-planning` does not re-evaluate. Override with explicit re-init.
3. **Cross-corpus edge resolution timing**: at index time + invalidate on neighbor reindex. Faster query path; handled invalidation logic during 2.1.0.
4. **`domains:` as soft edge**: skipped from the graph; used as a search-time boost only.
5. **Code-edge scope for v1**: `imports` + `defines` only. `calls` deferred (heaviest extraction; prove value of `imports`/`defines` first).
6. **Drift scope unit**: per-claim with severity bucketing (granular but with rollup summary).
7. **Drift severity model**: thresholds in `corpora.json` with sensible defaults.
8. **Drift findings sink**: response only by default; vault sink optional via `--sink` flag.
9. **HEWTD release coordination**: develop persistent-planning + semantic-memory against a local-link to in-progress HEWTD 2.2.0; ship coordinated.

## Errors Encountered
- *(none yet)*

## Status
**Ready to begin Phase 1.0.0 (Regression-snapshot baseline).** All load-bearing decisions confirmed:
- Rebrand to `semantic-memory` ✓
- persistent-planning drops MCP ✓
- Smart-middle corpus activation ✓
- Dependency-first then parallelism (3.x extensions + 4.2.0–4.7.0 testing + 4.8.0–4.13.0 docs all parallelizable for agent teams) ✓
- Version bump to 1.0.0 ✓
- babel-fish three integration points (corpus + glossary + translation verbs) ✓
- Per-plugin testing AND documentation in each respective repo (4.2.0–4.13.0, one task per plugin × per concern) ✓

**Total scope**: 4 phases, 23 tasks across 6 repos (HEWTD, persistent-planning, semantic-memory, babel-fish, semantic-pages, dev-stack). 1.x sequential foundation. 2.x sequential semantic-memory core. 3.x parallelizable extensions. 4.x distribution: sequential through 4.1.0, then 4.2.0–4.7.0 (testing) and 4.8.0–4.13.0 (docs) parallelizable across agent teams (each repo's testing + docs is independent), 4.14.0 sequential consolidation.

**Next concrete action**: capture golden snapshots of every existing semantic-sidekick MCP tool BEFORE any code changes (Phase 1.0.0). This is the regression gate that protects the no-silent-breakage commitment. Once snapshots are locked into CI, Phase 1.1.0 (HEWTD 2.2.0 schema extension) can begin in parallel with 1.2.0/1.3.0 work in persistent-planning.
