#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY=false
CLEANUP=false
BREWFILE="Brewfile.base"

usage() {
    echo "Usage: $0 [OPTIONS] [BREWFILE]"
    echo ""
    echo "Options:"
    echo "  --apply       Update Homebrew and install the selected bundle"
    echo "  --cleanup     Run brew cleanup after a successful install"
    echo "  -n, --dry-run Check bundle satisfaction without changes (default)"
    echo "  -h, --help    Show this help message"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) APPLY=true; shift ;;
        --cleanup) CLEANUP=true; shift ;;
        -n|--dry-run) APPLY=false; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *) BREWFILE="$1"; shift ;;
    esac
done

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Review and install it from https://brew.sh before continuing." >&2
    exit 1
fi

case "$BREWFILE" in
    /*) BREWFILE_PATH="$BREWFILE" ;;
    homebrew/*) BREWFILE_PATH="$DOTFILES/$BREWFILE" ;;
    *) BREWFILE_PATH="$DOTFILES/homebrew/$BREWFILE" ;;
esac

if [ ! -f "$BREWFILE_PATH" ]; then
    echo "Brewfile not found: $BREWFILE_PATH" >&2
    exit 1
fi

if [ "$APPLY" = false ]; then
    echo "[DRY-RUN] Checking $BREWFILE_PATH"
    if ! brew bundle check --file="$BREWFILE_PATH" --verbose; then
        echo "[DRY-RUN] Dependencies are missing or outdated. Run with --apply to install them."
    fi
    exit 0
fi

echo "Updating Homebrew..."
brew update

if grep -q 'brew "moshi-hook"' "$BREWFILE_PATH"; then
    brew trust --formula rjyo/moshi/moshi-hook
fi

brew bundle install --file="$BREWFILE_PATH"

if [ "$CLEANUP" = true ]; then
    brew cleanup
fi

echo "Homebrew bundle installed."
