#!/usr/bin/env bash
# Toggle the space-layout plugin. Disabling clears its $run1..$run8 sidebar
# rows; enabling redraws them right away instead of waiting for the next event.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
plugin_id="dotfiles.space-layout"
max_rows=8
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

enabled="$("$herdr" plugin list --plugin "$plugin_id" --json | jq -r '.result.plugins[0].enabled')"

if [[ "$enabled" == "true" ]]; then
  "$herdr" plugin disable "$plugin_id" >/dev/null
  seq="$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')"
  args=()
  for ((i = 1; i <= max_rows; i++)); do
    args+=(--clear-token "run$i")
  done
  for ws in $("$herdr" workspace list | jq -r '.result.workspaces[].workspace_id'); do
    "$herdr" workspace report-metadata "$ws" --source "$plugin_id" --seq "$seq" "${args[@]}" >/dev/null ||
      echo "clearing rows failed for workspace $ws" >&2
  done
else
  "$herdr" plugin enable "$plugin_id" >/dev/null
  HERDR_PLUGIN_ID="$plugin_id" "$script_dir/report-layout.sh"
fi
