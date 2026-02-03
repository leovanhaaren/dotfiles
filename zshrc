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

# 1Password SSH Agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Proton Pass SSH Agent
# export SSH_AUTH_SOCK=/Users/leo/.ssh/proton-pass-agent.sock

# Path
export PATH="$HOME/.local/bin:$PATH"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go
export PATH="$PATH:$(go env GOPATH)/bin"

# Editor
export EDITOR="code --wait"

# eval "$(mise activate zsh)"

source /Users/leo/Workspaces/tools/taskdown/scripts/td-greeting.sh

source <(_HASS_CLI_COMPLETE=zsh_source hass-cli)

export HASS_SERVER=pass://Development/hass-cli/HASS_SERVER
export HASS_TOKEN=pass://Development/hass-cli/HASS_TOKEN