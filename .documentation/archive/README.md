# Archive

This folder holds **deprecated documentation** — docs that are retired but
worth keeping (historical reference, superseded guides, old runbooks).

## Don't move files here by hand — use the command

```bash
hewtd archive <file> --reason "why"     # e.g. hewtd archive api/old-webhooks.md
```

`hewtd archive` does it properly: it moves the doc into
`archive/<same-domain-path>/`, preserves git history (`git mv`), stamps
lifecycle metadata (`status: archived`, `archived_on`, `archived_from`), and
regenerates the indexes so the doc cleanly leaves the active set. It also
**refuses if other active docs still link to the doc** (so you don't create
dead links) — pass `--force` to override after you've reviewed them.

## Reversible

```bash
hewtd unarchive <file>                  # restores to its original path, status: active
```

The `archived_from` field records the exact restore path, so un-archiving is
lossless.

## Finding what to archive

```bash
hewtd archive-candidates                # advisory list — never moves anything
```

Suggests docs worth retiring, ranked by signal: `status: deprecated` (strongest),
`superseded_by:`, orphaned (no inbound links), and age (only when also orphaned).
Age alone never qualifies a doc — an unchanged doc is often your most important one.

## hewtd ignores this folder

Everything under `archive/` is **excluded from every hewtd scan** — `audit`,
`link-check`, `metadata-sync`, `integrate` duplicate-detection, the link
graph, and `search`. Archived docs are not validated, never appear in any
INDEX.md / REGISTRY.md, and can't break audit/link-check with stale frontmatter.

> Note: `archive/` is a reserved name. You cannot create a custom domain
> called `archive`.
