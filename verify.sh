#!/bin/bash

DOTFILES="$HOME/Workspaces/leovanhaaren/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ERRORS++))
}

check_symlink() {
    local target="$1"
    local expected_source="$2"
    local description="$3"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        log_error "$description: Missing ($target)"
        return 1
    fi

    if [ ! -L "$target" ]; then
        log_warn "$description: Exists but not a symlink ($target)"
        return 1
    fi

    local actual_source
    actual_source=$(readlink "$target")
    if [ "$actual_source" = "$expected_source" ]; then
        log_ok "$description"
        return 0
    else
        log_warn "$description: Points to wrong location ($actual_source instead of $expected_source)"
        return 1
    fi
}

check_directory() {
    local dir="$1"
    local description="$2"

    if [ -d "$dir" ]; then
        log_ok "$description"
        return 0
    else
        log_error "$description: Missing ($dir)"
        return 1
    fi
}

check_command() {
    local cmd="$1"
    local description="$2"

    if command -v "$cmd" &> /dev/null; then
        log_ok "$description"
        return 0
    else
        log_warn "$description: Not installed"
        return 1
    fi
}

check_file_executable() {
    local file="$1"
    local description="$2"

    if [ -x "$file" ]; then
        log_ok "$description"
        return 0
    else
        log_warn "$description: Not executable ($file)"
        return 1
    fi
}

echo ""
echo "=== Verifying Dotfiles Installation ==="
echo ""

# Check dotfiles directory
echo "Checking dotfiles directory..."
check_directory "$DOTFILES" "Dotfiles directory"
echo ""

# Check shell symlinks
echo "Checking shell configuration..."
check_symlink "$HOME/.zshrc" "$DOTFILES/zshrc" "zshrc"
check_symlink "$HOME/.zprofile" "$DOTFILES/zprofile" "zprofile"
check_symlink "$HOME/.aliases" "$DOTFILES/aliases" "aliases"
echo ""

# Check git configuration
echo "Checking git configuration..."
check_symlink "$HOME/.gitconfig" "$DOTFILES/gitconfig" "gitconfig"
echo ""

# Check bin directory
echo "Checking bin scripts..."
check_directory "$HOME/bin" "Bin directory"
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        check_symlink "$HOME/bin/$scriptname" "$script" "bin/$scriptname"
    fi
done
echo ""

# Check Claude CLI
echo "Checking Claude CLI configuration..."
check_directory "$HOME/.claude" "Claude config directory"
check_symlink "$HOME/.claude/settings.json" "$DOTFILES/.claude/settings.json" "Claude settings"
check_symlink "$HOME/.claude/prompts" "$DOTFILES/claude/prompts" "Claude prompts"
echo ""

# Check key dependencies
echo "Checking dependencies..."
check_command "git" "Git"
check_command "zsh" "Zsh"
check_command "brew" "Homebrew"
echo ""

# Check script permissions
echo "Checking script permissions..."
check_file_executable "$DOTFILES/setup.sh" "setup.sh"
check_file_executable "$DOTFILES/uninstall.sh" "uninstall.sh"
check_file_executable "$DOTFILES/verify.sh" "verify.sh"
echo ""

# Summary
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
    echo "To fix errors, run: ./setup.sh"
    exit 1
fi
