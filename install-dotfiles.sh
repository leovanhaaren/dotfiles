brew install rcm

cd ~/
git clone git@github.com:leovanhaaren/dotfiles.git

cd ~/dotfiles
cp ~/dotfiles/rcrc ~/

mkdir ~/dotfiles-local
rcup -v

source ~/.zshrc