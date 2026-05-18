#!/bin/bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((ERRORS++)); }

resolve_path() {
    if command -v realpath &>/dev/null; then
        realpath "$1" 2>/dev/null
    else
        python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$1" 2>/dev/null
    fi
}

check_symlink() {
    local target="$1"
    local expected_source="$2"
    local description="$3"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        log_error "$description: missing ($target)"
        return 1
    fi

    if [ ! -L "$target" ]; then
        log_warn "$description: exists but not a symlink ($target)"
        return 1
    fi

    local resolved
    resolved=$(resolve_path "$target")
    if [ "$resolved" = "$expected_source" ]; then
        log_ok "$description"
    else
        log_warn "$description: resolves to $resolved, expected $expected_source"
        return 1
    fi
}

check_command() {
    local cmd="$1"
    local description="$2"
    if command -v "$cmd" &>/dev/null; then
        log_ok "$description"
    else
        log_warn "$description: not installed"
    fi
}

echo ""
echo "=== Verifying Dotfiles Installation ($OS) ==="
echo ""

echo "Checking stow-managed dotfiles (~/)..."
check_symlink "$HOME/.zshrc"      "$DOTFILES/.zshrc"      "zshrc"
check_symlink "$HOME/.zprofile"   "$DOTFILES/.zprofile"   "zprofile"
check_symlink "$HOME/.aliases"    "$DOTFILES/.aliases"    "aliases"
check_symlink "$HOME/.functions"  "$DOTFILES/.functions"  "functions"
check_symlink "$HOME/.gitconfig"  "$DOTFILES/.gitconfig"  "gitconfig"
check_symlink "$HOME/.tmux.conf"  "$DOTFILES/.tmux.conf"  "tmux.conf"
check_symlink "$HOME/.gitmux.conf" "$DOTFILES/.gitmux.conf" "gitmux.conf"
echo ""

echo "Checking stow-managed XDG config (~/.config/)..."
check_symlink "$HOME/.config/starship.toml"             "$DOTFILES/.config/starship.toml"             "starship.toml"
check_symlink "$HOME/.config/ghostty"                   "$DOTFILES/.config/ghostty"                   "ghostty"
check_symlink "$HOME/.config/fish/config.fish"          "$DOTFILES/.config/fish/config.fish"          "fish/config.fish"
check_symlink "$HOME/.config/fish/functions/wt.fish"    "$DOTFILES/.config/fish/functions/wt.fish"    "fish/functions/wt.fish"
check_symlink "$HOME/.config/nvim/init.lua"             "$DOTFILES/.config/nvim/init.lua"             "nvim/init.lua"
check_symlink "$HOME/.config/nvim/lua"                  "$DOTFILES/.config/nvim/lua"                  "nvim/lua"
check_symlink "$HOME/.config/wezterm/wezterm.lua"       "$DOTFILES/.config/wezterm/wezterm.lua"       "wezterm/wezterm.lua"
check_symlink "$HOME/.config/zed/settings.json"         "$DOTFILES/.config/zed/settings.json"         "zed/settings.json"
check_symlink "$HOME/.config/sesh/sesh.toml"            "$DOTFILES/.config/sesh/sesh.toml"            "sesh/sesh.toml"
check_symlink "$HOME/.config/television/config.toml"    "$DOTFILES/.config/television/config.toml"    "television/config.toml"
check_symlink "$HOME/.config/television/cable/sesh.toml" "$DOTFILES/.config/television/cable/sesh.toml" "television/cable/sesh.toml"
check_symlink "$HOME/.config/worktrunk/config.toml"     "$DOTFILES/.config/worktrunk/config.toml"     "worktrunk/config.toml"
echo ""

echo "Checking stow-managed bin scripts (~/bin/)..."
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        check_symlink "$HOME/bin/$scriptname" "$script" "bin/$scriptname"
    fi
done
echo ""

echo "Checking platform-specific configuration (manually linked)..."
case "$OS" in
    Darwin) check_symlink "$HOME/.ssh/config"  "$DOTFILES/ssh/config.macos" "ssh/config" ;;
    Linux)  check_symlink "$HOME/.ssh/config"  "$DOTFILES/ssh/config.linux" "ssh/config" ;;
esac
case "$OS" in
    Darwin)
        check_symlink "$HOME/Library/Application Support/Code/User/settings.json" \
            "$DOTFILES/vscode/settings.json" "vscode/settings.json"
        ;;
    Linux)
        check_symlink "$HOME/.config/Code/User/settings.json" \
            "$DOTFILES/vscode/settings.json" "vscode/settings.json"
        ;;
esac
echo ""

echo "Checking tools..."
check_command "stow"     "GNU Stow"
check_command "git"      "Git"
check_command "zsh"      "Zsh"
check_command "nvim"     "Neovim"
check_command "starship" "Starship"
[ "$OS" = "Darwin" ] && check_command "brew" "Homebrew"
echo ""

echo "=== Verification Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}Failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "To fix: ./setup.sh"
    exit 1
fi
