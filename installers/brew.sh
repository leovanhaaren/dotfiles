#!/bin/bash

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

brew bundle install

echo "Cleaning up brew"
brew cleanup

echo "Done!"