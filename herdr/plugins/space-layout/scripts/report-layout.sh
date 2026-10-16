#!/usr/bin/env bash
# Report "<tabs>t <panes>p" for every workspace as the $layout token.
# Every run recomputes all workspaces, so a hook that fires out of order
# self-corrects; the millisecond seq makes herdr drop reports from older snapshots.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
source_id="${HERDR_PLUGIN_ID:-dotfiles.space-layout}"
seq="$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')"

"$herdr" workspace list |
  jq -r '.result.workspaces[] | [.workspace_id, "\(.tab_count)t \(.pane_count)p"] | @tsv' |
  while IFS=$'\t' read -r workspace_id layout; do
    "$herdr" workspace report-metadata "$workspace_id" \
      --source "$source_id" --seq "$seq" --token "layout=$layout" >/dev/null
  done
