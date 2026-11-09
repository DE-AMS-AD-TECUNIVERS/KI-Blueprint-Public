# Dependabot PR processor — reference

## Resolving merge conflicts (DIRTY) without downgrading

A Dependabot conflict is almost always in the **lockfile** (`package-lock.json`,
`poetry.lock`) and sometimes the manifest (`package.json`, `pyproject.toml`).
Do **not** hand-merge lockfile JSON. Regenerate it from a correctly merged
manifest instead.

### Preferred: let Dependabot rebase (only if you have not pushed)

If the PR conflicts but needs **no** project-code fix, and you have **not** yet
pushed a manual commit to it, comment on the PR:

```
@dependabot rebase
```

Dependabot regenerates the lockfile against the current base. Re-check after CI.
This keeps the branch under Dependabot's management. Use it whenever it suffices.

### Manual: when you have taken over the branch or also need a code fix

```sh
gh pr checkout <n>
git fetch origin <baseRefName>
git rebase origin/<baseRefName>        # or: git merge origin/<baseRefName>
```

Resolve the manifest conflict by keeping the **higher** version for every
conflicting dependency (never the lower). Then drop the conflicted lockfile and
regenerate it cleanly:

- **frontend:** `cd frontend && npm install` (regenerates `package-lock.json`).
- **backend (poetry):** resolve `pyproject.toml`, then `poetry lock --no-update`.
- **backend (pip-tools):** resolve `requirements.in`, then `pip-compile --upgrade`.

Continue the rebase (`git rebase --continue`), verify locally, then
`git push --force-with-lease` to the PR branch.

## The no-downgrade check (run before every push)

After regenerating any lockfile, confirm nothing moved **down** relative to the
base branch:

```sh
# frontend example — eyeball versions that decreased vs base
git diff origin/<baseRefName> -- frontend/package-lock.json | grep -E '^\s*[-+]\s*"version"'
```

For the Dependabot-bumped package specifically, confirm it sits at **≥** both the
base version and the version the PR originally proposed. If any package would end
up lower than base to make CI pass, **stop and report** — do not push.

## Diagnosing a failing check

```sh
gh pr checks <n>                          # which job failed
gh run view --job <job-id> --log-failed   # raw log (mostly setup noise)
```

Filter the log for signal — `error`, `fail`, `FAIL`, `npm err`, `exit code`,
`Cannot find`, `ERR_`. The real failure is usually one or two lines among
hundreds of setup lines.

Then `gh pr checkout <n>`, reproduce locally, fix the **project** side, and
verify before pushing. The fix is config/code/lockfile — it is **never**
downgrading or reverting the bump.

## Worked example (the case this skill came from)

PR: bump `@mui/icons-material` 9.0.1 → 9.1.1. The CI lint/test job failed — many
test suites crashed at import with `ERR_UNSUPPORTED_DIR_IMPORT`.

- **Cause:** the icons bump pulled the whole MUI suite to 9.1.x via peer deps.
  `@mui/material@9.1.x`'s `internal/Transition.mjs` does a directory import of
  `react-transition-group/TransitionGroupContext`; that subpath is a legacy
  directory package (no `exports` map), which Node's native ESM resolver rejects
  when the dep is externalized by Vitest.
- **Why not "update other versions":** `@mui/material` 9.1.1 was already
  `latest`, and `react-transition-group` was frozen at 4.4.5 — no forward move
  existed. The only version change available was a **downgrade**, which the rule
  forbids.
- **Fix (project side, no downgrade):** add `/@mui\//` to `server.deps.inline`
  in `vitest.config.mjs` so Vite's resolver handles the directory import — the
  same mechanism already used for `axios`.
- **Verified:** `npx vitest run` → all test files pass. Then committed only the
  config file and pushed to the PR branch.

This is the template: the bump stays; the project adapts to it.

## Command cheatsheet

```sh
# List open Dependabot PRs for the repo in the current directory
gh pr list --state open --author "app/dependabot" \
  --json number,title,mergeStateStatus,headRefName,baseRefName

# Full state of one PR
gh pr view <n> --json number,title,mergeStateStatus,mergeable,headRefName,baseRefName

# Update a BEHIND branch from its base
gh pr update-branch <n>

# Dependabot branch comments (only before you push manual commits)
#   @dependabot rebase     – rebase onto base, regenerate lockfile
#   @dependabot recreate   – rebuild the PR from scratch
```

mergeStateStatus values: `CLEAN` (green/ready), `UNSTABLE` (mergeable, a check is
red/pending), `DIRTY` (conflicts), `BEHIND` (base ahead), `BLOCKED` (branch
protection / required review).
