---
name: code-review
description: 'Code review for a Python/FastAPI backend (example project). Repo-aware checks for security, domain-organized Active Record (Beanie) architecture, clean code, tests, and domain-model integrity, with a judgment-based severity rubric and a PR-ready report. Use when: reviewing code, PR review, code quality check, "review this", "check this code", audit a module/domain, checking architecture or auth compliance, security review before merge.'
argument-hint: 'File path, module/domain name, branch/PR diff, or describe what to review (add "PR comment" for a ready-to-paste Markdown file)'
---

# Code Review

Structured, repo-aware review for an example backend (FastAPI + Beanie/MongoDB,
domain-organized **Active Record**, async, external cloud integrations).

> **Template note:** This skill is a neutralized example. Paths, domain names, and rules
> describe a fictional order/approval backend. Replace them with your own project's
> conventions (`AGENTS.md`, glossary, ADRs) before use.

This file is the entry point and **router**: it defines the *process*, the *severity
rubric*, the *confidence bar*, and the *report format*, then points to detailed
reference files. Load only the reference files relevant to what you are reviewing.

## When to use

- Reviewing a PR or set of changes
- Auditing a domain module or service
- Checking architecture / auth compliance after a change
- Security review before merge
- Hunting for bugs, smells, or drift

## 1. Process — gather context

Identify the scope:

- **Single file** → read it.
- **Domain / module** → all files under `app/domains/<name>/`, including nested
  sub-domains (e.g. `order/approval/`, `reporting/dashboard/`).
- **PR / branch diff** → determine the integration base branch (the branch this repo
  integrates into, e.g. `dev` or `main` — see `AGENTS.md`). Accept an explicit base as an
  argument; otherwise default to `origin/<integration-branch>`. Then:
  - `git fetch` — so the base isn't stale.
  - `git diff --name-only origin/<base>...HEAD` — enumerate changed files.
  - `git diff origin/<base>...HEAD` — the hunks. Three-dot diffs against the merge-base and
    includes committed work (a bare `git diff` would miss committed-but-unpushed changes).
  - **Fail fast:** confirm the base resolves (`git rev-parse origin/<base>` or the explicit
    base) and the three-dot diff is non-empty. A bad ref or empty diff stops the review here
    with a clear message — it must not surface later as an empty or misdirected report.
  - Review every changed file; read surrounding context as needed.

Whatever the scope, two rules bind the review:

- **Find the canonical sibling.** Classify the change by what it *produces* (a generated
  file/download, a notification mail, a webhook, a paginated list, …) — not by which
  domain it lives in — and search repo-wide, **outside the changed domain first**, for
  existing implementations of that output category. Search by transport marker, not file
  format (`Content-Disposition` for downloads, the mail-sending helper for notifications — a
  CSV export's siblings are the existing file downloads, not other CSVs). The sibling
  defines which layer does which work (in particular: who builds the content vs. who wraps
  it in the response) and outranks generic framework intuition; judge divergence per
  [references/clean-code.md](./references/clean-code.md). For each category the change
  adds, fill the report's canonical-sibling line (§5) with the sibling compared against —
  or the exact search terms that came up empty. A doc or ADR added by the PR itself is
  part of the diff under review, not an established standard that can endorse the code.
- **A re-review re-applies every dimension to the full base…HEAD diff, as if it were the
  first round** — not just to the commits added since the last round.

Then read **only the reference files the change touches** (next section).

Report in the user's language — German in, German out.

## 2. Check index — load what's relevant

Each dimension's detailed checklist lives in a reference file. Open the ones the change
touches (these are Markdown links so both Claude Code and Copilot load them on demand):

- **Security** → [references/security.md](./references/security.md) — authorization &
  object-level access (BOLA/IDOR), signed inbound webhooks, injection (incl. Mongo
  operators), secrets/config, input validation, error-response leakage, DoS, dependency
  hygiene. **Always load for any change to an endpoint, auth, query, file handling,
  logging, config, or dependencies.**
- **Architecture** → [references/architecture.md](./references/architecture.md) — Active
  Record placement, layer responsibilities, domain boundaries, project-specific placement
  rules.
- **Clean code** → [references/clean-code.md](./references/clean-code.md) — naming &
  consistency, DRY & cross-module duplication, dead code, reuse-over-reinvention,
  overcomplication/KISS, general smells, stale comments, error handling, async, types.
- **Domain-model integrity** → [references/domain-integrity.md](./references/domain-integrity.md)
  — state machine, split sources of truth / drift, concurrency, idempotency,
  migration/back-compat.
- **Tests** → [references/testing.md](./references/testing.md) — missing, tautological,
  and over-mocked tests, error-path and async pitfalls.

## 2b. Spec faithfulness (when reviewing a diff with an originating spec)

For PR/branch reviews, also check the diff against what was actually asked for:

- Locate the originating issue/spec: references in commit messages (`#123`, `Closes #45`) —
  fetch via `docs/agents/issue-tracker.md` — or a path the user gave. If none exists, note
  "no spec available" and skip this dimension.
- Report: (a) required behaviour that is missing or partial; (b) behaviour added that wasn't
  asked for (scope creep); (c) requirements that look implemented but wrong.
- Keep these findings under their own `### Spec faithfulness` heading in the report, apart
  from the standards findings, so that neither kind of finding hides the other.
- **Flag, don't fix:** where the code intentionally diverges from a stale/ambiguous spec,
  surface it as a question for the human, not a defect; divergences already documented in-repo
  need no action unless they conflict with an ADR.

## 3. Severity — judgment, not a lookup table

Three levels, assigned by **judgment**, not a fixed per-rule label. Weigh:

- **Exploitability / likelihood** — can it actually be triggered, and by whom?
- **Blast radius** — one leaf DTO vs. a shared `app/core` module touched by every handler.
- **Hot path** — is it on a critical flow? (e.g. the import pipeline, document processing,
  per-aggregate locking, the sub-workflow ↔ parent-status sync, signed webhooks, auth). The
  repo's critical flows are listed in `AGENTS.md`.
- **Reversibility** — silent data drift / corruption vs. a cosmetic nit.

- **MAJOR** — must fix before merge: exploitable security flaw, broken or bypassed domain
  invariant, data-integrity / drift risk, missing auth, architecture violation on a hot path.
- **MODERATE** — should fix: tech debt, deviation from an established convention/pattern,
  untested new logic, duplication that can drift.
- **MINOR** — nice to have: naming, local readability, micro-optimizations.

The *same* issue moves between levels by context: a sync SDK call blocking the event loop
is **MAJOR** on the import hot path, **MINOR** in a one-off admin script. A duplicated auth
check is **MAJOR** (drift becomes a security hole); duplicated test boilerplate is
**MINOR**.

## 4. Confidence — report only what you can stand behind

- **Cite a real line** (`file.py:NN`) for every finding. If you can't point at the exact
  code, don't report it.
- **Don't speculate.** If a finding needs runtime confirmation, label it
  `⚠ possible — verify` and say what to check; don't assert it as fact.
- **Condense nits.** Lead with what matters; batch trivial style points into one line. A
  wall of MINORs that buries the one MAJOR is a failed review.
- Prefer "no finding" to a padded list. Silence on a clean dimension is a valid result.

## 5. Report

Open with an overall verdict, then group findings by file (or by domain for large PRs),
with exact line numbers. Each finding = *what* + *why it matters here* + a concrete fix.
Close with a summary table. When the diff adds a new capability, a canonical-sibling line
(§1) directly follows the verdict — the report is incomplete without it.

Verdict line: `🔴 BLOCK` (any MAJOR) · `🟡 APPROVE WITH NITS` (MODERATE/MINOR only) ·
`🟢 LGTM`.

Default output is an inline report. **PR-comment mode** — when the user asks for a PR
comment / a file, or when an agent invokes this skill — additionally write a ready-to-paste
Markdown file with Ist→Vorschlag (current vs. suggested) code examples and a closing
summary plus next steps.

```
## Code Review: <branch / scope>  —  🔴 BLOCK | 🟡 APPROVE WITH NITS | 🟢 LGTM
**Canonical sibling:** <category> → `path/to/sibling.py` (or: none — searched `<terms>`)

### app/domains/<...>/<file>.py
- **MAJOR — <short title>** (`file.py:42`)
  <what's wrong and why it matters in this codebase>
  *Fix:* <concrete suggestion>
- **MINOR — <short title>** (`file.py:88`)
  ...

### Summary
| Prio | File:Line | Finding | Fix effort |
|------|-----------|---------|-----------|
| MAJOR | file.py:42 | ... | Low / Med / High |
```

Omit any severity section with no findings.
