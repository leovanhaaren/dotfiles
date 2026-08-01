#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
DRY_RUN=true
ADOPT=false

# shellcheck source=scripts/lib/managed-links.sh
source "$DOTFILES/scripts/lib/managed-links.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --apply          Apply the planned changes"
    echo "  -n, --dry-run    Show what would be done without making changes (default)"
    echo "  --adopt          Explicitly adopt conflicting files into a clean repository"
    echo "  -h, --help       Show this help message"
    exit 0
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

resolve_path() {
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1" 2>/dev/null
    else
        python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$1" 2>/dev/null
    fi
}

backup_path() {
    local target="$1"
    local candidate="${target}.backup.$(date +%Y%m%d-%H%M%S)"
    local counter=1
    while [ -e "$candidate" ] || [ -L "$candidate" ]; do
        candidate="${target}.backup.$(date +%Y%m%d-%H%M%S).$counter"
        counter=$((counter + 1))
    done
    printf '%s\n' "$candidate"
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
        current_source=$(resolve_path "$target" || true)
        if [ "$current_source" = "$source" ]; then
            log_info "Already linked: $target"
            return 0
        fi
        log_warn "Replacing existing symlink: $target (was: ${current_source:-unresolved})"
    elif [ -e "$target" ]; then
        local backup
        backup=$(backup_path "$target")
        log_warn "Backing up existing file: $target -> $backup"
        if [ "$DRY_RUN" = false ]; then
            mv "$target" "$backup"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would link: $source -> $target"
    else
        mkdir -p "$(dirname "$target")"
        ln -sfn "$source" "$target"
        log_info "Linked: $source -> $target"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --apply) DRY_RUN=false; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        --adopt) ADOPT=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if [ "$OS" != "Darwin" ]; then
    log_error "Unsupported operating system: $OS. Only macOS is supported."
    exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
    log_error "GNU Stow not found. Install with: brew install stow"
    exit 1
fi

if [ "$ADOPT" = true ] && [ "$DRY_RUN" = false ]; then
    if [ -n "$(git -C "$DOTFILES" status --porcelain)" ]; then
        log_error "--adopt requires a clean Git working tree"
        exit 1
    fi
    mkdir -p "$DOTFILES/backups"
    BUNDLE="$DOTFILES/backups/dotfiles-before-adopt-$(date +%Y%m%d-%H%M%S).bundle"
    git -C "$DOTFILES" bundle create "$BUNDLE" HEAD
    log_warn "Created canonical repository backup: $BUNDLE"
    log_warn "Before rollback, copy adopted file contents out of the repository, then restore canonical files from Git or the bundle"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Setting up dotfiles ($OS) ==="
fi
echo ""

log_info "Stowing dotfiles..."
STOW_FLAGS=(--dir "$DOTFILES" --target "$HOME" --restow)
[ "$ADOPT" = true ] && STOW_FLAGS+=(--adopt)
[ "$DRY_RUN" = true ] && STOW_FLAGS+=(--simulate)
stow "${STOW_FLAGS[@]}" .
log_info "Dotfiles stow plan completed."

log_info "Setting up manually managed links..."
while IFS=$'\t' read -r description source target; do
    log_info "$description"
    create_symlink "$source" "$target"
done < <(managed_manual_links)

if [ "$DRY_RUN" = false ]; then
    chmod 700 "$HOME/.ssh"
fi

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
    log_info "TPM already installed: $TPM_DIR"
else
    log_warn "TPM is not installed. Review and install it explicitly from https://github.com/tmux-plugins/tpm"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run with --apply to apply changes ==="
else
    echo "=== Setup complete ==="
    echo ""
    echo "Next steps:"
    echo "  1. source ~/.zshrc"
    echo "  2. ./scripts/brew.sh --apply"
    echo "  3. ./scripts/mac.sh --apply"
fi
