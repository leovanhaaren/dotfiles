#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
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
    echo "=== Setting up dotfiles ($OS) ==="
fi
echo ""

# Shell configuration
log_info "Setting up shell configuration..."
create_symlink "$DOTFILES/shell/zshrc" "$HOME/.zshrc"
case "$OS" in
    Darwin) create_symlink "$DOTFILES/shell/zprofile.macos" "$HOME/.zprofile" ;;
    Linux)  create_symlink "$DOTFILES/shell/zprofile.linux" "$HOME/.zprofile" ;;
esac
create_symlink "$DOTFILES/shell/aliases" "$HOME/.aliases"
create_symlink "$DOTFILES/shell/functions" "$HOME/.functions"

# Platform-specific shell configuration
log_info "Setting up platform-specific shell configuration..."
case "$OS" in
    Darwin) create_symlink "$DOTFILES/shell/zshrc.macos" "$HOME/.zshrc.platform" ;;
    Linux)  create_symlink "$DOTFILES/shell/zshrc.linux" "$HOME/.zshrc.platform" ;;
esac

# Git configuration
log_info "Setting up git configuration..."
create_symlink "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"

# SSH configuration
log_info "Setting up SSH configuration..."
create_directory "$HOME/.ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true
case "$OS" in
    Darwin) create_symlink "$DOTFILES/ssh/config.macos" "$HOME/.ssh/config" ;;
    Linux)  create_symlink "$DOTFILES/ssh/config.linux" "$HOME/.ssh/config" ;;
esac

# Export SSH public keys from 1Password (macOS only)
if [ "$OS" = "Darwin" ]; then
    log_info "Exporting SSH public keys from 1Password..."
    export_ssh_pubkey "SSH Key leovhaaren@gmail.com" "my.1password.eu" "$HOME/.ssh/id_leovanhaaren.pub" || true
    export_ssh_pubkey "Github Authentication key" "ksyos.1password.com" "$HOME/.ssh/id_leo_ksyos.pub" || true
fi

# Bin directory
log_info "Setting up bin directory..."
create_directory "$HOME/bin"
for script in "$DOTFILES/bin/"*; do
    if [ -f "$script" ]; then
        scriptname=$(basename "$script")
        # Skip hidden files like .env.example
        if [[ "$scriptname" != .* ]]; then
            create_symlink "$script" "$HOME/bin/$scriptname"
        fi
    fi
done

# Zed editor
log_info "Setting up Zed configuration..."
create_directory "$HOME/.config/zed"
create_symlink "$DOTFILES/zed/settings.json" "$HOME/.config/zed/settings.json"

# VS Code
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

# Tmux
log_info "Setting up tmux configuration..."
create_symlink "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# Install TPM (Tmux Plugin Manager) and plugins
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
    log_info "TPM already installed: $TPM_DIR"
else
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would clone TPM to $TPM_DIR"
    else
        if command -v git &>/dev/null; then
            git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1
            log_info "Installed TPM: $TPM_DIR"
        else
            log_warn "git not found - skipping TPM installation"
        fi
    fi
fi

# Install tmux plugins via TPM
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install tmux plugins via TPM"
    else
        "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1
        log_info "Installed tmux plugins via TPM"
    fi
fi

# Neovim
log_info "Setting up Neovim configuration..."
create_directory "$HOME/.config/nvim"
create_symlink "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
create_symlink "$DOTFILES/nvim/lua" "$HOME/.config/nvim/lua"
create_symlink "$DOTFILES/nvim/stylua.toml" "$HOME/.config/nvim/stylua.toml"
create_symlink "$DOTFILES/nvim/.neoconf.json" "$HOME/.config/nvim/.neoconf.json"

# Starship prompt
log_info "Setting up Starship configuration..."
create_directory "$HOME/.config"
create_symlink "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"

# Ghostty terminal (macOS only)
if [ "$OS" = "Darwin" ]; then
    log_info "Setting up Ghostty configuration..."
    create_directory "$HOME/Library/Application Support/com.mitchellh.ghostty"
    create_symlink "$DOTFILES/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
fi

# WezTerm terminal
log_info "Setting up WezTerm configuration..."
create_directory "$HOME/.config/wezterm"
create_symlink "$DOTFILES/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

# Fish shell
log_info "Setting up Fish configuration..."
create_directory "$HOME/.config/fish/conf.d"
create_directory "$HOME/.config/fish/functions"
create_symlink "$DOTFILES/fish/config.fish" "$HOME/.config/fish/config.fish"
for conf in "$DOTFILES/fish/conf.d/"*.fish; do
    if [ -f "$conf" ]; then
        create_symlink "$conf" "$HOME/.config/fish/conf.d/$(basename "$conf")"
    fi
done
for func in "$DOTFILES/fish/functions/"*.fish; do
    if [ -f "$func" ]; then
        create_symlink "$func" "$HOME/.config/fish/functions/$(basename "$func")"
    fi
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Symlinks created successfully ==="
    echo ""
    echo "Next steps:"
    echo "  1. Run 'source ~/.zshrc' to reload shell configuration"
    if [ "$OS" = "Darwin" ]; then
        echo "  2. Run './install/brew.sh' to install Homebrew packages"
        echo "  3. Run './install/mac.sh' to apply macOS preferences"
    else
        echo "  2. Run './install/ubuntu.sh' to install Ubuntu packages"
    fi
fi
