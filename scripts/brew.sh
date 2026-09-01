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
    echo "  -n, --dry-run Show the selected bundle plan without invoking Homebrew (default)"
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
    echo "[DRY-RUN] Would update Homebrew and install $BREWFILE_PATH"
    [ "$CLEANUP" = true ] && echo "[DRY-RUN] Would run brew cleanup after installation"
    echo "Run with --apply to make changes."
    exit 0
fi

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Review and install it from https://brew.sh before continuing." >&2
    exit 1
fi

echo "Updating Homebrew..."
brew update

brew bundle install --file="$BREWFILE_PATH"

if [ "$CLEANUP" = true ]; then
    brew cleanup
fi

echo "Homebrew bundle installed."
