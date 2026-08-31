#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=true
MODE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 --nix|--classic [OPTIONS]"
    echo ""
    echo "Install modes:"
    echo "  --nix            Declarative install via nix-darwin + home-manager"
    echo "  --classic        Stow symlinks + Homebrew scripts (no Nix required)"
    echo ""
    echo "Options:"
    echo "  --apply          Apply the planned changes"
    echo "  -n, --dry-run    Show what would be done without making changes (default)"
    echo "  -h, --help       Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --nix) MODE="nix"; shift ;;
        --classic) MODE="classic"; shift ;;
        --apply) DRY_RUN=false; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$MODE" ]; then
    if command -v nix >/dev/null 2>&1 || [ -x /nix/var/nix/profiles/default/bin/nix ]; then
        MODE="nix"
        log_info "Nix detected; defaulting to --nix (pass --classic to override)"
    else
        MODE="classic"
        log_info "Nix not found; defaulting to --classic (see docs/nix-adoption-plan.md for the Nix path)"
    fi
fi

run_classic() {
    log_info "Classic install: GNU Stow symlinks + Homebrew scripts"
    if [ "$DRY_RUN" = true ]; then
        "$DOTFILES/setup.sh" --dry-run
        "$DOTFILES/scripts/brew.sh"
        echo ""
        log_info "Dry run complete. Apply with: $0 --classic --apply"
    else
        "$DOTFILES/setup.sh" --apply
        "$DOTFILES/scripts/brew.sh" --apply
        echo ""
        log_info "Optional: preview macOS preferences with ./scripts/mac.sh"
    fi
}

run_nix() {
    local nix_bin="nix"
    if ! command -v nix >/dev/null 2>&1; then
        if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
            nix_bin="/nix/var/nix/profiles/default/bin/nix"
        else
            log_error "Nix is not installed. Install Determinate Nix first:"
            log_error "  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate"
            log_error "Or install without Nix: $0 --classic"
            exit 1
        fi
    fi

    # Match this machine against the flake's host entries. The names
    # scutil reports (LocalHostName, HostName, ComputerName) can all
    # differ, so try each until one is a darwinConfigurations attr.
    local flake_hosts host candidate key
    if ! flake_hosts="$("$nix_bin" eval --json "$DOTFILES#darwinConfigurations" --apply builtins.attrNames)"; then
        log_error "Could not read darwinConfigurations from the flake."
        exit 1
    fi
    host=""
    for key in LocalHostName HostName ComputerName; do
        candidate="$(scutil --get "$key" 2>/dev/null)" || continue
        if [ -n "$candidate" ] && printf '%s' "$flake_hosts" | grep -qF "\"$candidate\""; then
            host="$candidate"
            break
        fi
    done
    if [ -z "$host" ]; then
        log_error "No darwinConfigurations entry matches this machine."
        log_error "Machine names: LocalHostName=$(scutil --get LocalHostName 2>/dev/null), HostName=$(scutil --get HostName 2>/dev/null), ComputerName=$(scutil --get ComputerName 2>/dev/null)"
        log_error "Flake hosts: $flake_hosts"
        log_error "Add hosts/<name>.nix and a matching entry in flake.nix."
        exit 1
    fi

    log_info "Nix install: building darwinConfigurations.\"$host\""
    if ! "$nix_bin" build "$DOTFILES#darwinConfigurations.\"$host\".system" --out-link "$DOTFILES/result"; then
        log_error "Build failed; see the Nix error above."
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "System closure built at ./result; nothing was activated."
        log_info "Inspect the pending change, then apply with: $0 --nix --apply"
    else
        log_info "Activating (requires sudo)..."
        sudo "$DOTFILES/result/sw/bin/darwin-rebuild" switch --flake "$DOTFILES#$host"
        log_info "Activation complete. Roll back anytime with: darwin-rebuild --rollback"
    fi
}

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Installing dotfiles ($MODE) ==="
fi
echo ""

case $MODE in
    nix) run_nix ;;
    classic) run_classic ;;
esac
