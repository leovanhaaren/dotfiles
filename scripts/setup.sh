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

###########
### Git ###
###########
echo "Installing Git..."
brew install git

echo "Git config"

# Ask the user for git config
read -p 'Git username: ' usernamevar
read -p 'Git email: ' emailvar
echo
echo "Thankyou ${usernamevar} (${emailvar})"

git config --global user.name "${usernamevar}"
git config --global user.email ${emailvar}
git config --global init.defaultBranch main

# echo "Installing brew git utilities..."
brew install git-extras
brew install legit
brew install git-flow

echo "Installing other brew stuff..."
brew install tree
brew install wget
brew install trash
brew install node
brew install nvm

brew install iterm2
brew install google-chrome
brew install 1password
brew install 1password-cli
brew install visual-studio-code
brew install notion
brew install alfred
brew install bartender
brew install bettertouchtool
brew install cleanmymac
brew install firefox

echo "Cleaning up brew"
brew cleanup

echo "Done!"