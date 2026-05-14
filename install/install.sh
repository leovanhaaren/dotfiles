#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Install Homebrew if not installed
"$DOTFILES/install/brew.sh"

# git clone https://github.com/dracula/zsh.git "$ZSH_CUSTOM/themes/dracula-prompt"
# ln -s "$ZSH_CUSTOM/themes/dracula-prompt/dracula.zsh-theme" "$ZSH_CUSTOM/themes/dracula.zsh-theme"

# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
