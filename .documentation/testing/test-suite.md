---
title: Test Suite
tier: guide
domains:
  - testing
audience:
  - developers
tags: []
status: active
last_updated: '2026-08-31'
version: 1.0.0
purpose: What tests/run.sh covers, how to run it, how to add an assertion, and
  why the suite is plain bash rather than a framework.
estimated_read_time: 3 minutes
word_count: 450
last_validated: '2026-08-31'
backlinks: []
---

# Test Suite

`tests/run.sh` is the whole test suite. It is plain bash with assert helpers —
no framework, no fixtures, no dependencies beyond what the scripts under test
already need.

## Why bash and not a framework

Everything under test *is* bash. `init-planning.sh`, `init-phase.sh`,
`init-task.sh`, `init-atom.sh`, and `detect-mode.sh` are shell scripts whose
observable behavior is "what landed on disk." A JS test runner would add a
dependency, a config file, and a translation layer between the runner and the
thing being run, to assert the same `grep`s. The suite stays in the language of
its subject.

The suite is also the thing that makes the
[mandatory closing phases](../standards/mandatory-closing-phases.md) enforceable rather than
aspirational: a template edit that pushes a checkbox below the closing pair turns
the suite red.

## How to run it

```bash
npm test           # preferred
bash tests/run.sh  # identical, no npm needed
```

Output is one line per assertion and a `N passed, M failed` summary. Exit status
is non-zero if anything failed, so it drops into CI unchanged.

## What it covers

| Group | Asserts |
|---|---|
| sm mode | `task_plan.md` + `notes.md` land at the slugified path; the plan seeds 6 phases; validation is second-to-last and documentation is last; the ordering rule text is present; the task name is substituted; re-running does not clobber an edited plan |
| lg mode | `detect-mode.sh` honors the `workspace.json` override; `phase.md` + `notes.md` are created; the two closing tasks are last and in order; HEWTD `tier: plan` frontmatter is present; no `PLACEHOLDER` tokens survive rendering; `task.md` is created with the right `parent:`; atom `sequence:` auto-increments 1 → 2 |
| mode guards | `init-phase.sh` exits non-zero in sm mode |

Every test runs the real script against a throwaway `CLAUDE_PROJECT_DIR` created
with `mktemp -d`, then removes it. Nothing touches the repository's own
`.planning/` tree.

## How to add an assertion

Use the helpers already in the file — `assert_eq`, `assert_contains`,
`assert_file`, and `checkbox_lines` (which extracts the checkbox lines of a named
markdown section). A new case looks like:

```bash
WS=$(new_workspace)
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Some Task" >/dev/null
assert_contains "$WS/.planning/some-task/task_plan.md" "## Goal" "plan has a Goal section"
rm -rf "$WS"
```

**Then prove the assertion can fail.** Break the template on purpose, run
`npm test`, confirm the new line goes red, and restore it. An assertion that has
never failed is not known to test anything.

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `no unsubstituted placeholders remain` fails | A template gained a `*_PLACEHOLDER` token with no matching substitution arg | Add the `KEY=value` pair to the matching `planning_render_and_log` call |
| `init-phase.sh refuses to run in sm mode` fails | The lg-mode guard was dropped from an init script | Restore the `planning_mode` check |
| Every lg assertion fails at once | `templates/lg/` not resolvable from the script directory | Check the `TEMPLATE_DIR` fallback chain in the init scripts |
| Tests pass locally, lg mode broken for installed users | `templates/` or `scripts/` missing from the `files` array in `package.json` | Add them, verify with `npm pack` before publishing |

That last row is not hypothetical — it is exactly how v3.0.0 shipped broken.
