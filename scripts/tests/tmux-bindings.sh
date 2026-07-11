#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SOCKET="dotfiles-bindings-test-$$"

cleanup() {
    tmux -L "$SOCKET" kill-server 2>/dev/null || true
}
trap cleanup EXIT

tmux -L "$SOCKET" -f /dev/null new-session -d -s bindings-test
tmux -L "$SOCKET" bind-key -T prefix T display-message "old Sesh binding"
tmux -L "$SOCKET" source-file "$ROOT/.tmux.conf"

bindings=$(tmux -L "$SOCKET" list-keys -T prefix)
printf '%s\n' "$bindings" | awk '$4 == "S"' | grep -q 'tv sesh'
printf '%s\n' "$bindings" | awk '$4 == "A"' | grep -q 'tv agent-sessions'
if printf '%s\n' "$bindings" | awk '$4 == "T"' | grep -q .; then
    echo "stale prefix+T binding remains after reload" >&2
    exit 1
fi
