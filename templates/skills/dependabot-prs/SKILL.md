---
name: dependabot-prs
description: Finds open Dependabot PRs in the frontend and backend repos, checks whether each is mergeable and green, and diagnoses + fixes failures (merge conflicts, lockfile drift, build/test/config breakage from a bump) before pushing the fix to the PR branch. Core rule — never downgrade a dependency; only upgrade when needed to satisfy peers or resolve conflicts. Merges problem-free PRs (green + mergeable) directly; only stops-and-reports when reaching green would require a downgrade or other human judgment. Use when asked to process, triage, unblock, fix, or merge Dependabot PRs, to check whether dependency-bump PRs are ready to merge, or to resolve conflicts on Dependabot branches.
---

# Dependabot PR processor

Scan open Dependabot PRs in the **frontend** and **backend** repos, get each to a
green, mergeable state, push any fixes to the PR branch — and **merge the
problem-free ones directly** (green + mergeable, no downgrade). Stop and report
only the PRs that need human judgment.

Checkout locations differ per developer, but the two repos always sit **side by
side under one parent, named after their GitHub repos**: resolve the frontend
root via `git rev-parse --show-toplevel` and the backend as
`<frontend-root>/../<backend-repo>` (the scan script does this itself — set the
backend repo name there). If the sibling checkout is missing, ask the user for
its path.

> **Template note:** This skill merges problem-free PRs without asking. Only use
> that mode if the target branch is protected by required status checks that
> cover build and tests. Otherwise switch step 4 of the quick start to "report and
> wait for confirmation" before merging.

## The one rule: never downgrade

Only ever move a version **up**. When resolving a conflict, fixing a peer-dep
error, or reconciling a lockfile, keep the **highest** version of each package
and upgrade siblings if needed. Never revert the Dependabot bump or pin anything
lower to make CI pass — that defeats the PR and can reintroduce a vulnerability.
If green is only reachable by downgrading, **stop and report** instead of pushing.

## Quick start

1. Scan both repos:
   `bash .claude/skills/dependabot-prs/scripts/scan-dependabot.sh`
2. For each PR, branch on its `mergeStateStatus` (see Workflow).
3. Fix → **verify locally** → push to the PR branch (autonomously, no confirm).
4. Merge each problem-free PR directly (green + mergeable), then report a per-PR summary.

## Workflow (per PR)

Read state first:
`gh pr view <n> -R <owner/repo> --json number,title,mergeStateStatus,mergeable,headRefName,baseRefName`

- **CLEAN** → problem-free (green + mergeable). **Merge it directly** (see
  Merging), then report it as merged.
- **UNSTABLE / BLOCKED with a red check** → a check is failing or pending:
  1. `gh pr checks <n>` to find the failing job.
  2. `gh run view --job <id> --log-failed` → grep for `error|fail|FAIL` (the dump
     is mostly setup noise; filter it).
  3. `gh pr checkout <n>`, reproduce locally, then fix the **project**
     (config/code/lockfile) — not by downgrading the bump.
  4. Verify locally (per-repo commands below), then commit + push. Once CI
     re-confirms green, the PR is now problem-free — **merge it** (see Merging).
- **DIRTY (merge conflicts)** → resolve conflicts. See [REFERENCE.md](REFERENCE.md).
- **BEHIND (base moved ahead)** → `gh pr update-branch <n>`, or if you have not
  pushed manual commits yet, comment `@dependabot rebase`. Re-check after CI runs.

After any push, CI re-runs automatically — confirm with `gh pr checks <n>`.

## Merging

A PR is **problem-free** when its checks are green and it is mergeable (CLEAN) —
either out of the box, or after a no-downgrade fix you pushed and CI re-confirmed
green. Merge a problem-free PR directly (autonomously, no confirm):

`gh pr merge <n> -R <owner/repo> --squash --delete-branch`

(Use the repo's allowed merge method if squash is disabled.)

**Do not merge — stop and report instead — when:**
- green is only reachable by **downgrading** (the one rule), or
- a conflict or fix needs human judgment you can't safely make, or
- required checks are still pending — re-check first, merge once green.

## Verify locally before pushing

| Repo | Install | Verify |
|------|---------|--------|
| frontend | `npm install` in `frontend/` | `npx vitest run` (and/or `npm run build`) |
| backend  | per repo (`pip install -e .` / `poetry install`) | the repo's test suite (e.g. `pytest`) |

On Windows, `npm ci` can fail with `EPERM unlink` on a locked native binding when
a dev server is running — use `npm install` (minimal reconcile) instead.

## Important caveats

- **Pushing takes over the branch.** Once you push a manual commit, Dependabot
  stops auto-rebasing/recreating that PR. Always note this in your summary.
- Commit **only** the fix file(s); never commit `node_modules` or stray lockfile
  churn. Run `git status --short` before committing.
- Merge only **problem-free** PRs (green + mergeable, reached without a
  downgrade). Never `gh pr merge` a still-red, conflicted, or downgrade-only PR —
  stop and report those instead.

See [REFERENCE.md](REFERENCE.md) for conflict resolution, the no-downgrade check,
and a worked example.
