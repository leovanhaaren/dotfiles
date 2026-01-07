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

create_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_error "Source does not exist: $source"
        return 1
    fi

    if [ -L "$target" ]; then
        local current_source
        current_source=$(readlink "$target")
        if [ "$current_source" = "$source" ]; then
            log_info "Already linked: $target"
            return 0
        else
            log_warn "Replacing existing symlink: $target (was: $current_source)"
        fi
    elif [ -e "$target" ]; then
        log_warn "Backing up existing file: $target -> $target.backup"
        if [ "$DRY_RUN" = false ]; then
            mv "$target" "$target.backup"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would link: $source -> $target"
    else
        ln -sf "$source" "$target"
        log_info "Linked: $source -> $target"
    fi
}

create_directory() {
    local dir="$1"

    if [ -d "$dir" ]; then
        log_info "Directory exists: $dir"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would create directory: $dir"
    else
        mkdir -p "$dir"
        log_info "Created directory: $dir"
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

# Verify dotfiles directory exists
if [ ! -d "$DOTFILES" ]; then
    log_error "Dotfiles directory not found: $DOTFILES"
    exit 1
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Setting up dotfiles ==="
fi
echo ""

# Shell configuration
log_info "Setting up shell configuration..."
create_symlink "$DOTFILES/zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES/zprofile" "$HOME/.zprofile"
create_symlink "$DOTFILES/aliases" "$HOME/.aliases"

# Git configuration
log_info "Setting up git configuration..."
create_symlink "$DOTFILES/gitconfig" "$HOME/.gitconfig"

# Bin directory
log_info "Setting up bin directory..."
create_directory "$HOME/bin"
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        create_symlink "$script" "$HOME/bin/$scriptname"
    fi
done

# Claude CLI
log_info "Setting up Claude CLI configuration..."
create_directory "$HOME/.claude"
create_symlink "$DOTFILES/claude/agents" "$HOME/.claude/agents"
create_symlink "$DOTFILES/claude/prompts" "$HOME/.claude/prompts"

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Symlinks created successfully ==="
    echo ""
    echo "Next steps:"
    echo "  1. Run 'source ~/.zshrc' to reload shell configuration"
    echo "  2. Run './installers/brew.sh' to install Homebrew packages"
    echo "  3. Run './installers/mac.sh' to apply macOS preferences"
fi
