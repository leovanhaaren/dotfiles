#!/bin/bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OS="$(uname -s)"

# shellcheck source=scripts/lib/managed-links.sh
source "$DOTFILES/scripts/lib/managed-links.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((ERRORS++)); }

if [ "$OS" != "Darwin" ]; then
    log_error "Unsupported operating system: $OS. Only macOS is supported."
    exit 1
fi

resolve_path() {
    if command -v realpath >/dev/null 2>&1; then
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

    local resolved expected
    resolved=$(resolve_path "$target" || true)
    expected=$(resolve_path "$expected_source" || true)
    if [ -n "$expected" ] && [ "$resolved" = "$expected" ]; then
        log_ok "$description"
    else
        log_error "$description: resolves to ${resolved:-unresolved}, expected $expected_source"
        return 1
    fi
}

check_command() {
    local cmd="$1"
    local description="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        log_ok "$description"
    else
        log_warn "$description: not installed"
    fi
}

check_stow_state() {
    local output status drift
    output=$(LC_ALL=C stow --dir "$DOTFILES" --target "$HOME" --restow --no-folding --simulate --verbose=2 . 2>&1)
    status=$?
    if [ "$status" -ne 0 ]; then
        log_error "GNU Stow could not validate the installation"
        printf '%s\n' "$output" | tail -10
        return 1
    fi

    drift=$(printf '%s\n' "$output" | sed -n '/^LINK:/ { /reverts previous action/!p; }')
    if [ -n "$drift" ]; then
        log_error "Stow-managed paths are missing or stale"
        printf '%s\n' "$drift"
        return 1
    fi
    log_ok "complete GNU Stow link set"
}

echo ""
echo "=== Verifying Dotfiles Installation ($OS) ==="
echo ""

echo "Checking stow-managed dotfiles..."
if command -v stow >/dev/null 2>&1; then
    check_stow_state
else
    log_error "GNU Stow is required to validate managed links"
fi
while IFS=$'\t' read -r description source target; do
    check_symlink "$target" "$source" "$description"
done < <(managed_stow_links)
echo ""

echo "Checking stow-managed bin scripts..."
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        check_symlink "$HOME/bin/$scriptname" "$script" "bin/$scriptname"
    fi
done
echo ""

echo "Checking manually managed links..."
while IFS=$'\t' read -r description source target; do
    check_symlink "$target" "$source" "$description"
done < <(managed_manual_links)
echo ""

echo "Checking tools..."
check_command "stow"     "GNU Stow"
check_command "git"      "Git"
check_command "zsh"      "Zsh"
check_command "nvim"     "Neovim"
check_command "starship" "Starship"
check_command "brew"     "Homebrew"
check_command "bun"      "Bun"
check_command "tmux"     "Tmux"
check_command "jq"       "jq"
if "$DOTFILES/bin/nvim-plugins" verify --allow-missing; then
    log_ok "present Neovim plugins match the lock file"
else
    log_error "Neovim plugin integrity"
fi
echo ""

echo "=== Verification Summary ==="
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${YELLOW}Passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}Failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Preview repairs with: ./setup.sh"
    echo "Apply repairs with: ./setup.sh --apply"
    exit 1
fi
