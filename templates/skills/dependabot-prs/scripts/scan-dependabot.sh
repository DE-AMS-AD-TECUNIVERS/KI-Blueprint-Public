#!/usr/bin/env bash
# Lists open Dependabot PRs and their merge state for the given repo dirs.
# Usage: scan-dependabot.sh [repo-dir ...]
# With no args, defaults to the frontend and backend repos.
set -uo pipefail

dirs=("$@")
if [ ${#dirs[@]} -eq 0 ]; then
  # Sibling-checkout convention: this script lives at
  # <fe-repo>/.claude/skills/dependabot-prs/scripts/, and the backend checkout
  # sits beside the frontend one, named after its GitHub repo. Override with
  # FRONTEND_DIR / BACKEND_DIR (each holds the repo ROOT) or explicit args.
  # Adjust BACKEND_REPO_NAME to your backend repository's name.
  BACKEND_REPO_NAME="my-backend"
  script_dir=$(cd "$(dirname "$0")" && pwd)
  fe_root=$(cd "$script_dir/../../../.." && pwd)
  dirs=(
    "${FRONTEND_DIR:-$fe_root}"
    "${BACKEND_DIR:-$fe_root/../$BACKEND_REPO_NAME}"
  )
fi

for dir in "${dirs[@]}"; do
  if [ ! -d "$dir/.git" ]; then
    echo "## $dir  (not a git repo — skipped)"
    echo
    continue
  fi
  echo "## $dir"
  (
    cd "$dir" || exit
    gh pr list --state open --author "app/dependabot" \
      --json number,title,mergeStateStatus,headRefName,baseRefName \
      --jq '.[] | "  #\(.number)  [\(.mergeStateStatus)]  \(.title)\n        \(.headRefName) -> \(.baseRefName)"' \
      2>&1 || echo "  (gh error — check auth / repo access)"
  )
  echo
done

cat <<'EOF'
Legend (mergeStateStatus):
  CLEAN     green, ready to merge        -> merge per SKILL.md (or report, if confirm mode)
  UNSTABLE  mergeable, a check is red    -> diagnose & fix the failing check
  DIRTY     merge conflicts              -> resolve conflicts (never downgrade)
  BEHIND    base branch moved ahead      -> update branch / rebase
  BLOCKED   branch protection / review   -> report; usually needs a human

Rule: only ever upgrade a version, never downgrade.
EOF
