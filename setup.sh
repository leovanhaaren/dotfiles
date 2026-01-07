#!/bin/bash
DOTFILES="$HOME/Workspaces/leovanhaaren/dotfiles"

ln -sf "$DOTFILES/zshrc" ~/.zshrc
ln -sf "$DOTFILES/zprofile" ~/.zprofile
ln -sf "$DOTFILES/aliases" ~/.aliases
ln -sf "$DOTFILES/gitconfig" ~/.gitconfig

echo "Symlinks created"
