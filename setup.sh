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
        fi
        log_warn "Replacing existing symlink: $target (was: $current_source)"
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
    if [ -d "$dir" ]; then return 0; fi
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would create directory: $dir"
    else
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

export_ssh_pubkey() {
    local item="$1"
    local account="$2"
    local target="$3"

    if [ -f "$target" ]; then
        log_info "Already exists: $target"
        return 0
    fi

    if ! command -v op &>/dev/null; then
        log_warn "1Password CLI (op) not found - skipping $target"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would export public key from 1Password: $item -> $target"
        return 0
    fi

    local pubkey
    pubkey=$(op item get "$item" --account "$account" --fields "public key" 2>/dev/null)
    if [ -z "$pubkey" ]; then
        log_error "Failed to read public key from 1Password: $item ($account)"
        return 1
    fi

    echo "$pubkey" > "$target"
    chmod 600 "$target"
    log_info "Exported public key: $item -> $target"
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
    echo "=== Setting up dotfiles ($OS) ==="
fi
echo ""

# Stow all XDG-compatible dotfiles
log_info "Stowing dotfiles..."
STOW_FLAGS=(--dir "$DOTFILES" --target "$HOME" --restow)
[ "$DRY_RUN" = true ] && STOW_FLAGS+=(--simulate)
stow "${STOW_FLAGS[@]}" .
log_info "Dotfiles stowed."

# SSH configuration (platform-specific config)
log_info "Setting up SSH configuration..."
create_directory "$HOME/.ssh"
[ "$DRY_RUN" = false ] && chmod 700 "$HOME/.ssh" 2>/dev/null || true
case "$OS" in
    Darwin) create_symlink "$DOTFILES/ssh/config.macos" "$HOME/.ssh/config" ;;
    Linux)  create_symlink "$DOTFILES/ssh/config.linux" "$HOME/.ssh/config" ;;
esac

# SSH public keys from 1Password (macOS only)
if [ "$OS" = "Darwin" ]; then
    log_info "Exporting SSH public keys from 1Password..."
    export_ssh_pubkey "SSH Key leovhaaren@gmail.com" "my.1password.eu" "$HOME/.ssh/id_leovanhaaren.pub" || true
    export_ssh_pubkey "Github Authentication key" "ksyos.1password.com" "$HOME/.ssh/id_leo_ksyos.pub" || true
fi

# VS Code (non-XDG path on macOS, not stow-able)
log_info "Setting up VS Code configuration..."
case "$OS" in
    Darwin)
        create_directory "$HOME/Library/Application Support/Code/User"
        create_symlink "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
        ;;
    Linux)
        create_directory "$HOME/.config/Code/User"
        create_symlink "$DOTFILES/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
        ;;
esac

# Tmux Plugin Manager
log_info "Setting up Tmux Plugin Manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
    log_info "TPM already installed: $TPM_DIR"
elif [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would clone TPM to $TPM_DIR"
else
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1
    log_info "Installed TPM: $TPM_DIR"
    "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1
    log_info "Installed tmux plugins"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Setup complete ==="
    echo ""
    echo "Next steps:"
    echo "  1. source ~/.zshrc"
    if [ "$OS" = "Darwin" ]; then
        echo "  2. ./install/brew.sh"
        echo "  3. ./install/mac.sh"
    else
        echo "  2. ./install/ubuntu.sh"
    fi
fi
