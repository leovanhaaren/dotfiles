# Disable terminal bell
# setopt NO_BEEP

# Homebrew
export HOMEBREW_TEMP=/tmp/homebrew

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
DISABLE_AUTO_TITLE="true"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

export DOTFILES_DIR="$HOME/Workspaces/leovanhaaren/dotfiles"
export DOT_AI_ROOT="$HOME/Workspaces/leovanhaaren/dot-ai"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.functions ]] && source ~/.functions

# Path
export PATH="$HOME/.local/bin:$PATH"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go
command -v go &>/dev/null && export PATH="$PATH:$(go env GOPATH)/bin"
export GOPRIVATE=github.com/leovanhaaren/*

# Editor
export EDITOR="code --wait"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Home Assistant CLI
command -v hass-cli &>/dev/null && source <(_HASS_CLI_COMPLETE=zsh_source hass-cli)
export HASS_SERVER=pass://Development/hass-cli/HASS_SERVER
export HASS_TOKEN=pass://Development/hass-cli/HASS_TOKEN

# Tmux
[[ -f ~/.tmux.conf ]] && export TMUX_CONF="$HOME/.tmux.conf"

# Taskdown
[[ -x "$(command -v td)" ]] && \
  source ~/Workspaces/leovanhaaren/taskdown/scripts/td-greeting.sh

# Starship prompt (must be at the end)
command -v starship &>/dev/null && eval "$(starship init zsh)"

eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
