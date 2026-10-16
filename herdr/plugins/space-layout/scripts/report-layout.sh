#!/usr/bin/env bash
# Report what runs in each workspace's panes as a tree list, one item per
# $run1..$run8 token so each renders on its own sidebar row. Workspaces with
# several tabs nest panes under their tab; unnamed tabs show as "tab N":
#   ├ editor
#   │ ├ nvim
#   │ └ zsh
#   └ tab 2
#     └ 󰚩  claude
# A pane shows its detected agent marked with a Nerd Font robot (nf-md-robot),
# otherwise its name, otherwise the leader of its foreground process group.
# Agents come first because integrations such as pi's recap rename panes with
# long session titles.
# Herdr has no hook for a shell starting a command, so every run refreshes all
# workspaces and focus changes catch up on them. The millisecond seq makes herdr
# drop reports from older snapshots.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
source_id="${HERDR_PLUGIN_ID:-dotfiles.space-layout}"
max_rows=8
seq="$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')"

workspace_ids="$("$herdr" workspace list | jq -r '.result.workspaces[].workspace_id')"

pane_name() {
  "$herdr" pane process-info --pane "$1" | jq -r '
    .result.process_info
    | .foreground_process_group_id as $pgid
    | (first(.foreground_processes[] | select(.pid == $pgid)) // .foreground_processes[0] // {})
    | .name // "?" | ltrimstr("-")' 2>/dev/null || echo "?"
}

for ws in $workspace_ids; do
  # The workspace may close between the event and these reads.
  tabs="$("$herdr" tab list --workspace "$ws" 2>/dev/null | jq -c '.result.tabs | sort_by(.number)')" || continue
  panes="$("$herdr" pane list --workspace "$ws" 2>/dev/null)" || continue
  rows=""
  while IFS=$'\t' read -r pane_id tab_id agent name; do
    rows+="$tab_id"$'\t'"$agent"$'\t'"${name:-$(pane_name "$pane_id")}"$'\n'
  done < <(jq -r '.result.panes[] | [.pane_id, .tab_id, (.agent != null), .agent // .label // ""] | @tsv' <<<"$panes")
  [[ -n "$rows" ]] || continue

  args=()
  i=0
  while IFS= read -r row; do
    i=$((i + 1))
    args+=(--token "run$i=$row")
  done < <(printf '%s' "$rows" | jq -Rrs --argjson max "$max_rows" --argjson tabs "$tabs" '
    def branch($items): ($items | length) as $n | $items | to_entries[]
      | {last: (.key == $n - 1), value};
    # The zero-width space keeps herdr from trimming the indent under the last tab.
    split("\n") | map(select(. != "") | split("\t") | {tab: .[0], name: (if .[1] == "true" then "\uDB81\uDEA9  " else "" end) + .[2]}) as $panes
    | if ($tabs | length) > 1 then
        [branch($tabs) as $t
         | (if $t.last then "└ " else "├ " end)
           + (if $t.value.label == ($t.value.number | tostring) then "tab \($t.value.number)" else $t.value.label end),
           (branch([$panes[] | select(.tab == $t.value.tab_id) | .name]) as $p
            | (if $t.last then "\u200b  " else "│ " end) + (if $p.last then "└ " else "├ " end) + $p.value)]
      else
        [branch([$panes[].name]) as $p | (if $p.last then "└ " else "├ " end) + $p.value]
      end
    | if length > $max then .[:$max - 1] + ["└ +\(length - $max + 1) more"] else . end
    | .[]')
  while ((i < max_rows)); do
    i=$((i + 1))
    args+=(--clear-token "run$i")
  done

  "$herdr" workspace report-metadata "$ws" --source "$source_id" --seq "$seq" "${args[@]}" >/dev/null ||
    echo "report-metadata failed for workspace $ws" >&2
done
