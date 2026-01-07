# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Autoenv
source /opt/homebrew/opt/autoenv/activate.sh

# Dotfiles
export PATH=$HOME/bin:$PATH
export PATH=$HOME/dotfiles/bin:$PATH
