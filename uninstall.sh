#!/bin/bash
set -e

DOTFILES="$HOME/Workspaces/leovanhaaren/dotfiles"
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show what would be done without making changes"
    echo "  -h, --help       Show this help message"
    exit 0
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

remove_symlink() {
    local target="$1"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        log_info "Does not exist: $target"
        return 0
    fi

    if [ -L "$target" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would remove symlink: $target"
        else
            rm -f "$target"
            log_info "Removed symlink: $target"
        fi
    else
        log_warn "Not a symlink, skipping: $target"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Removing dotfiles symlinks ==="
fi
echo ""

# Shell configuration
log_info "Removing shell configuration symlinks..."
remove_symlink "$HOME/.zshrc"
remove_symlink "$HOME/.zprofile"
remove_symlink "$HOME/.aliases"

# Git configuration
log_info "Removing git configuration symlinks..."
remove_symlink "$HOME/.gitconfig"

# Bin directory
log_info "Removing bin symlinks..."
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        remove_symlink "$HOME/bin/$scriptname"
    fi
done

# Claude CLI
log_info "Removing Claude CLI symlinks..."
remove_symlink "$HOME/.claude/agents"
remove_symlink "$HOME/.claude/settings.json"
remove_symlink "$HOME/.claude/prompts"

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Symlinks removed ==="
    echo ""
    echo "Note: Backup files (*.backup) were not removed."
    echo "To restore from backup: mv ~/.zshrc.backup ~/.zshrc"
fi
