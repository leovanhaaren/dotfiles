#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure we are on Ubuntu/Debian
if [ ! -f /etc/os-release ] || ! grep -qi 'ubuntu\|debian' /etc/os-release; then
    log_error "This script is intended for Ubuntu/Debian systems"
    exit 1
fi

log_info "Updating package lists..."
sudo apt-get update

# ──────────────────────────────────────────────
# APT packages (Brewfile.base equivalents)
# ──────────────────────────────────────────────
log_info "Installing APT packages..."
PACKAGES=(
    bat
    build-essential
    curl
    fzf
    git
    git-extras
    glances
    jq
    tmux
    tree
    unzip
    wget
    zsh
)
sudo apt-get install -y "${PACKAGES[@]}"

# ──────────────────────────────────────────────
# GitHub CLI (gh)
# ──────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
    log_info "Installing GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
else
    log_info "GitHub CLI already installed"
fi

# ──────────────────────────────────────────────
# eza (modern ls replacement)
# ──────────────────────────────────────────────
if ! command -v eza &>/dev/null; then
    log_info "Installing eza..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y eza
else
    log_info "eza already installed"
fi

# ──────────────────────────────────────────────
# Go (official tarball — apt version is often outdated)
# ──────────────────────────────────────────────
if ! command -v go &>/dev/null; then
    log_info "Installing Go..."
    GO_VERSION=$(curl -sL 'https://go.dev/VERSION?m=text' | head -1)
    curl -sLO "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
    rm -f "${GO_VERSION}.linux-amd64.tar.gz"
    export PATH="/usr/local/go/bin:$PATH"
else
    log_info "Go already installed ($(go version))"
fi

# ──────────────────────────────────────────────
# yq (YAML processor)
# ──────────────────────────────────────────────
if ! command -v yq &>/dev/null; then
    log_info "Installing yq..."
    sudo wget -qO /usr/local/bin/yq \
        https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
else
    log_info "yq already installed"
fi

# ──────────────────────────────────────────────
# Oh My Zsh
# ──────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log_info "Oh My Zsh already installed"
fi

# Oh My Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_info "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    log_info "zsh-autosuggestions already installed"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log_info "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    log_info "zsh-syntax-highlighting already installed"
fi

# ──────────────────────────────────────────────
# NVM (Node Version Manager)
# ──────────────────────────────────────────────
if [ ! -d "$HOME/.nvm" ]; then
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    log_info "NVM already installed"
fi

# ──────────────────────────────────────────────
# Bun
# ──────────────────────────────────────────────
if ! command -v bun &>/dev/null; then
    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
else
    log_info "Bun already installed"
fi

# ──────────────────────────────────────────────
# pnpm
# ──────────────────────────────────────────────
if ! command -v pnpm &>/dev/null; then
    log_info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
else
    log_info "pnpm already installed"
fi

# ──────────────────────────────────────────────
# Set default shell to zsh
# ──────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting default shell to zsh..."
    chsh -s "$(which zsh)"
else
    log_info "Default shell is already zsh"
fi

echo ""
log_info "Done! Restart your shell or run: exec zsh"
