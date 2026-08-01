#!/usr/bin/env bash

# Preview or create a Worktrunk-managed worktree for a GitHub pull request.

set -euo pipefail

APPLY=false
if [ "${1:-}" = "--apply" ]; then
  APPLY=true
  shift
fi

repo_path="${1:?usage: pr-worktree.sh [--apply] <repo-path> <pr-number>}"
pr_number="${2:?usage: pr-worktree.sh [--apply] <repo-path> <pr-number>}"

command -v wt >/dev/null 2>&1 || { echo "Worktrunk (wt) is required" >&2; exit 1; }

if [ "$APPLY" = false ]; then
  echo "[DRY-RUN] Would create or reuse the Worktrunk worktree for PR #$pr_number in $repo_path"
  echo "Run with --apply to create it."
  exit 0
fi

wt -C "$repo_path" switch "pr:$pr_number" --no-cd
