#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create dirs, ignore existing
mkdir -p ~/.claude
mkdir -p ~/.claude-glm
mkdir -p ~/.claude-work

copy_if_present() {
    local source="$1"
    local target="$2"

    if [ -f "$source" ]; then
        cp "$source" "$target"
        echo "Copied $source -> $target"
    else
        echo "Skipping missing config: $source"
    fi
}

# Copy configs
copy_if_present "$DOTFILES/.claude/settings.local.json" "$HOME/.claude/settings.local.json"
copy_if_present "$DOTFILES/.claude/settings-glm.json" "$HOME/.claude-glm/settings.json"
copy_if_present "$DOTFILES/.claude/settings-work.json" "$HOME/.claude-work/settings.json"
