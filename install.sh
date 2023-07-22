#!/bin/bash

ln -s $HOME/dotfiles/.git/hooks/pre-commit .git/hooks/pre-commit

cp $HOME/dotfiles/rcrc ~/.rcrc
cd $HOME/dotfiles || exit

rcup -v -y
source $HOME/.zshrc

reload