#!/bin/bash

# Install Homebrew if not installed
sh installers/brew.sh

# git clone https://github.com/dracula/zsh.git "$ZSH_CUSTOM/themes/dracula-prompt"
# ln -s "$ZSH_CUSTOM/themes/dracula-prompt/dracula.zsh-theme" "$ZSH_CUSTOM/themes/dracula.zsh-theme"

# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# ln -s $HOME/dotfiles/.git/hooks/pre-commit .git/hooks/pre-commit

# cp $HOME/dotfiles/rcrc ~/.rcrc
# cd $HOME/dotfiles || exit

# rcup -v -y
# source $HOME/.zshrc

# reload