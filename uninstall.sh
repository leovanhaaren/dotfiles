#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
DRY_RUN=true

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
    echo "  --apply          Remove links owned by this repository"
    echo "  -n, --dry-run    Show what would be done without making changes (default)"
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

remove_managed_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        log_info "Does not exist: $target"
        return 0
    fi

    if [ ! -L "$target" ]; then
        log_warn "Not a symlink, leaving untouched: $target"
        return 0
    fi

    local resolved
    resolved=$(resolve_path "$target" || true)
    if [ "$resolved" != "$source" ]; then
        log_warn "Not owned by this repository, leaving untouched: $target -> ${resolved:-unresolved}"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would remove symlink: $target"
    else
        rm "$target"
        log_info "Removed symlink: $target"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --apply) DRY_RUN=false; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
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

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Removing dotfiles symlinks ==="
fi
echo ""

log_info "Removing stow-managed dotfiles..."
STOW_FLAGS=(--dir "$DOTFILES" --target "$HOME" --delete)
[ "$DRY_RUN" = true ] && STOW_FLAGS+=(--simulate)
stow "${STOW_FLAGS[@]}" .
log_info "Stow-managed dotfiles plan completed."

log_info "Removing manually managed links..."
while IFS=$'\t' read -r description source target; do
    log_info "$description"
    remove_managed_symlink "$source" "$target"
done < <(managed_manual_links)

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run with --apply to remove links ==="
else
    echo "=== Repository-owned symlinks removed ==="
fi
