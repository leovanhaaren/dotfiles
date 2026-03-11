# Path
fish_add_path $HOME/.local/bin
fish_add_path $HOME/bin
fish_add_path $HOME/dotfiles/bin

# Bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $BUN_INSTALL/bin

# NVM (via nvm.fish plugin or manual)
set -gx NVM_DIR $HOME/.nvm

# Go
if command -q go
    fish_add_path (go env GOPATH)/bin
end
set -gx GOPRIVATE "github.com/leovanhaaren/*"

# Editor
set -gx EDITOR "code --wait"

# Starship prompt (must be at the end)
if command -q starship
    starship init fish | source
end
