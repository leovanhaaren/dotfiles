#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SANDBOX="$ROOT/.test-stow-$$"
cleanup() {
    rm -rf "$SANDBOX"
}
trap cleanup EXIT

if ! command -v stow >/dev/null 2>&1 || ! stow --version >/dev/null 2>&1; then
    echo "stow lifecycle skipped: GNU Stow is unavailable in this execution environment"
    exit 0
fi

mkdir -p "$SANDBOX/home"
HOME="$SANDBOX/home" "$ROOT/setup.sh" --apply > "$SANDBOX/setup.log"

[ -d "$SANDBOX/home/.config" ] && [ ! -L "$SANDBOX/home/.config" ] || { echo "expected an unfolded ~/.config directory" >&2; exit 1; }
[ -L "$SANDBOX/home/.config/starship.toml" ] || { echo "expected a leaf starship Stow link" >&2; exit 1; }
[ -d "$SANDBOX/home/bin" ] && [ ! -L "$SANDBOX/home/bin" ] || { echo "expected an unfolded ~/bin directory" >&2; exit 1; }
[ -L "$SANDBOX/home/bin/agent-sessions" ] || { echo "expected a leaf agent-sessions Stow link" >&2; exit 1; }
HOME="$SANDBOX/home" "$ROOT/verify.sh" > "$SANDBOX/verify.log"

rm "$SANDBOX/home/.config/fish/functions/acp.fish"
if HOME="$SANDBOX/home" "$ROOT/verify.sh" > "$SANDBOX/verify-missing.log" 2>&1; then
    echo "verification accepted a missing Stow-managed link" >&2
    exit 1
fi
HOME="$SANDBOX/home" "$ROOT/setup.sh" --apply > "$SANDBOX/setup-repair.log"
HOME="$SANDBOX/home" "$ROOT/verify.sh" > "$SANDBOX/verify-repaired.log"

HOME="$SANDBOX/home" "$SANDBOX/home/dotfiles/uninstall.sh" --apply > "$SANDBOX/uninstall.log"
if find "$SANDBOX/home" -type l -print | grep -q .; then
    echo "uninstall left repository-owned symlinks behind" >&2
    exit 1
fi

echo "stow lifecycle checks passed"
