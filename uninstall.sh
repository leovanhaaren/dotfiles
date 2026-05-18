#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
DRY_RUN=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show what would be done without making changes"
    echo "  -h, --help       Show this help message"
    exit 0
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

remove_symlink() {
    local target="$1"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        log_info "Does not exist: $target"
        return 0
    fi

    if [ ! -L "$target" ]; then
        log_warn "Not a symlink, skipping: $target"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would remove symlink: $target"
    else
        rm -f "$target"
        log_info "Removed symlink: $target"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if ! command -v stow &>/dev/null; then
    log_error "GNU Stow not found. Install with: brew install stow"
    exit 1
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Removing dotfiles symlinks ==="
fi
echo ""

# Remove all stow-managed symlinks
log_info "Removing stow-managed dotfiles..."
STOW_FLAGS=(--dir "$DOTFILES" --target "$HOME" --delete)
[ "$DRY_RUN" = true ] && STOW_FLAGS+=(--simulate)
stow "${STOW_FLAGS[@]}" .
log_info "Stow-managed dotfiles removed."

# Platform-specific symlinks (not managed by stow)
log_info "Removing platform-specific symlinks..."
remove_symlink "$HOME/dotfiles"
remove_symlink "$HOME/.zprofile"
remove_symlink "$HOME/.ssh/config"

# VS Code (non-XDG path, not managed by stow)
log_info "Removing VS Code symlinks..."
case "$OS" in
    Darwin) remove_symlink "$HOME/Library/Application Support/Code/User/settings.json" ;;
    Linux)  remove_symlink "$HOME/.config/Code/User/settings.json" ;;
esac

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Symlinks removed ==="
fi
