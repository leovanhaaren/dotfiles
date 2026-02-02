# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Path
export PATH="$HOME/bin:$HOME/dotfiles/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
