# Directory configuration
WORKSPACES_DIR="$HOME/Workspaces"
DOTFILES_DIR="$WORKSPACES_DIR/leovanhaaren/dotfiles"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases

# Platform-specific configuration
[[ -f ~/.zshrc.platform ]] && source ~/.zshrc.platform

# Path
export PATH="$HOME/.local/bin:$PATH"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go
export PATH="$PATH:$(go env GOPATH)/bin"

# Editor
export EDITOR="code --wait"

# eval "$(mise activate zsh)"
