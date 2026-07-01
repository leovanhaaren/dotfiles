#!/usr/bin/env bash
#
# pr-worktree.sh — check out a GitHub PR as a git worktree (no worktrunk CLI).
#
# Usage: pr-worktree.sh <repo-path> <pr-number>
#
# Creates (or reuses) a worktree at
#   ~/Workspaces/worktrees/<repo>/<sanitized-branch>
# mirroring the worktrunk `worktree-path` convention, then checks out the PR's
# head branch into it with `gh pr checkout` (handles fork PRs and tracking).
# Used as the gh-dash "Review" keybinding command.

set -euo pipefail

repo_path="${1:?usage: pr-worktree.sh <repo-path> <pr-number>}"
pr_number="${2:?usage: pr-worktree.sh <repo-path> <pr-number>}"

cd "$repo_path"

repo_name="$(basename "$repo_path")"
branch="$(gh pr view "$pr_number" --json headRefName --jq '.headRefName')"

# Filesystem-safe branch name: '/' and '\' become '-' (matches worktrunk sanitize).
sanitized="${branch//\//-}"
sanitized="${sanitized//\\/-}"
worktree_path="$HOME/Workspaces/worktrees/$repo_name/$sanitized"

if [ -d "$worktree_path" ]; then
  echo "Worktree already exists: $worktree_path"
  exit 0
fi

mkdir -p "$(dirname "$worktree_path")"

# Create the worktree detached at HEAD, then let `gh` resolve the PR head into
# it. Roll back the worktree if the checkout fails so nothing is left dangling.
git worktree add --detach "$worktree_path"
if ! (cd "$worktree_path" && gh pr checkout "$pr_number"); then
  git worktree remove --force "$worktree_path"
  echo "Failed to check out PR #$pr_number" >&2
  exit 1
fi

echo "Checked out PR #$pr_number ($branch) at:"
echo "  $worktree_path"
