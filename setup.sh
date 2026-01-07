#!/bin/bash
DOTFILES="$HOME/Workspaces/leovanhaaren/dotfiles"

ln -sf "$DOTFILES/zshrc" ~/.zshrc
ln -sf "$DOTFILES/zprofile" ~/.zprofile
ln -sf "$DOTFILES/aliases" ~/.aliases
ln -sf "$DOTFILES/gitconfig" ~/.gitconfig

# bin directory
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES/bin/"* "$HOME/bin/"

# Claude CLI
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES/claude/agents" "$HOME/.claude/agents"
ln -sf "$DOTFILES/claude/prompts" "$HOME/.claude/prompts"


echo "Symlinks created"
