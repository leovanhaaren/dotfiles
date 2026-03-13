#!/bin/bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################
### Homebrew ###
################
if test ! $(which brew); then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path
    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> /Users/$USER/.zshrc
fi

# Update homebrew recipes
echo "Updating homebrew..."
brew update

BREWFILE="${1:-Brewfile.personal}"
cd "$DOTFILES/homebrew" && brew bundle install --file="$BREWFILE"

echo "Cleaning up brew"
brew cleanup

echo "Done!"