#!/bin/bash
# Create dirs, ignore existing
mkdir -p ~/.claude
mkdir -p ~/.claude-glm
mkdir -p ~/.claude-work

# Copy configs
cp ~/dotfiles/claude/settings.json ~/.claude/settings.json
cp ~/dotfiles/claude/settings-glm.json ~/.claude-glm/settings.json
cp ~/dotfiles/claude/settings-work.json ~/.claude-work/settings.json
