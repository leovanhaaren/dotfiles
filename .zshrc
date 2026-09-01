# Disable terminal bell
# setopt NO_BEEP

# Homebrew
export HOMEBREW_TEMP=/private/var/db/homebrew/tmp

# Completion (previously initialized by Oh My Zsh)
autoload -Uz compinit && compinit

export DOTFILES_DIR="${${:-$HOME/.zshrc}:A:h}"
export DOT_AI_ROOT="$HOME/Workspaces/leovanhaaren/dot-ai"
export OBSIDIAN_VAULT="$HOME/Obsidian/Personal"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.functions ]] && source ~/.functions

# SSH keys
if [[ -x "$DOTFILES_DIR/scripts/ssh-load-keys.sh" ]] && \
  command -v pass-cli >/dev/null 2>&1 && \
  command -v ssh-add >/dev/null 2>&1; then
  "$DOTFILES_DIR/scripts/ssh-load-keys.sh" --if-empty --quiet </dev/null >/dev/null 2>&1 || true
fi

# Path
export PATH="$HOME/.local/bin:$PATH"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

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
[[ -x "$(command -v td)" && -f "$HOME/Workspaces/leovanhaaren/taskdown/scripts/td-greeting.sh" ]] && \
  source "$HOME/Workspaces/leovanhaaren/taskdown/scripts/td-greeting.sh"

# Shell integrations
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

[[ -d /opt/homebrew/opt/libpq/bin ]] && export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"

# Homebrew Zsh plugins
# Syntax highlighting must be loaded after the other Zsh integrations.
if command -v brew >/dev/null 2>&1; then
  _BREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
  [[ -r "$_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  unset _BREW_PREFIX
fi

