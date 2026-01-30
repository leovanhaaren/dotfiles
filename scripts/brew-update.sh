#!/usr/bin/env bash
# brew-update.sh - Update Brewfiles while preserving comments and formatting
#
# This script compares your installed packages with a Brewfile and:
# - Keeps existing entries with their comments intact
# - Adds new packages that are installed but not in the Brewfile
# - Optionally removes packages that are in Brewfile but not installed
#
# Usage: ./scripts/brew-update.sh [options] <brewfile>
#
# Options:
#   -n, --dry-run     Show what would change without modifying files
#   -r, --remove      Remove entries for uninstalled packages
#   -h, --help        Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
REMOVE_MISSING=false
BREWFILE=""

usage() {
    echo "Usage: $0 [options] <brewfile>"
    echo ""
    echo "Update a Brewfile while preserving comments and formatting."
    echo ""
    echo "Options:"
    echo "  -n, --dry-run     Show what would change without modifying files"
    echo "  -r, --remove      Remove entries for uninstalled packages"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 Brewfile.base           # Update base Brewfile"
    echo "  $0 -n Brewfile.work        # Dry run on work Brewfile"
    echo "  $0 -r Brewfile.personal    # Update and remove uninstalled packages"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_removed() {
    echo -e "${RED}[-]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -r|--remove)
            REMOVE_MISSING=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            BREWFILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$BREWFILE" ]]; then
    echo "Error: No Brewfile specified"
    usage
    exit 1
fi

# Resolve Brewfile path
if [[ ! "$BREWFILE" = /* ]]; then
    BREWFILE="$DOTFILES_DIR/$BREWFILE"
fi

if [[ ! -f "$BREWFILE" ]]; then
    echo "Error: Brewfile not found: $BREWFILE"
    exit 1
fi

log_info "Updating: $BREWFILE"
if $DRY_RUN; then
    log_info "Dry run mode - no changes will be made"
fi

# Create temp directory for working files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Dump currently installed packages
log_info "Dumping currently installed packages..."
brew bundle dump --force --file="$TEMP_DIR/current.brewfile" 2>/dev/null || true

# Extract package key from a line (type:name format)
get_package_key() {
    local line="$1"
    # Remove inline comments and trailing whitespace
    local cleaned
    cleaned=$(echo "$line" | sed 's/#.*$//' | sed 's/[[:space:]]*$//')

    # Extract type (tap, brew, cask, mas, vscode, go)
    local pkg_type
    pkg_type=$(echo "$cleaned" | awk '{print $1}')

    # Extract the package name/identifier
    local pkg_name
    case "$pkg_type" in
        tap|brew|cask|vscode|go)
            pkg_name=$(echo "$cleaned" | sed -E 's/^[a-z]+[[:space:]]+"([^"]+)".*/\1/')
            ;;
        mas)
            # For mas, use the app ID as identifier
            pkg_name=$(echo "$cleaned" | grep -oE 'id:[[:space:]]*[0-9]+' | sed 's/id:[[:space:]]*//')
            ;;
        *)
            pkg_name=""
            ;;
    esac

    if [[ -n "$pkg_name" ]]; then
        echo "${pkg_type}:${pkg_name}"
    fi
}

# Build list of existing package keys
log_info "Parsing existing Brewfile..."
existing_keys_file="$TEMP_DIR/existing_keys.txt"
existing_lines_file="$TEMP_DIR/existing_lines.txt"
> "$existing_keys_file"
> "$existing_lines_file"

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines, comments-only lines, and instance_eval lines
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ instance_eval ]]; then
        continue
    fi

    key=$(get_package_key "$line")
    if [[ -n "$key" ]]; then
        echo "$key" >> "$existing_keys_file"
        echo "$key	$line" >> "$existing_lines_file"
    fi
done < "$BREWFILE"

# Build list of installed package keys
log_info "Parsing installed packages..."
installed_keys_file="$TEMP_DIR/installed_keys.txt"
installed_lines_file="$TEMP_DIR/installed_lines.txt"
> "$installed_keys_file"
> "$installed_lines_file"

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    key=$(get_package_key "$line")
    if [[ -n "$key" ]]; then
        echo "$key" >> "$installed_keys_file"
        echo "$key	$line" >> "$installed_lines_file"
    fi
done < "$TEMP_DIR/current.brewfile"

# Find new packages (installed but not in Brewfile)
new_packages_file="$TEMP_DIR/new_packages.txt"
> "$new_packages_file"

while IFS= read -r key; do
    if ! grep -qxF "$key" "$existing_keys_file"; then
        # Get the line for this key
        pkg_line=$(grep "^${key}	" "$installed_lines_file" | cut -f2-)
        if [[ -n "$pkg_line" ]]; then
            echo "$pkg_line" >> "$new_packages_file"
            log_success "New: $pkg_line"
        fi
    fi
done < "$installed_keys_file"

# Find removed packages (in Brewfile but not installed)
removed_keys_file="$TEMP_DIR/removed_keys.txt"
> "$removed_keys_file"

while IFS= read -r key; do
    if ! grep -qxF "$key" "$installed_keys_file"; then
        echo "$key" >> "$removed_keys_file"
        pkg_line=$(grep "^${key}	" "$existing_lines_file" | cut -f2-)
        log_removed "Not installed: $pkg_line"
    fi
done < "$existing_keys_file"

# Count changes
total_new=$(wc -l < "$new_packages_file" | tr -d ' ')
total_removed=$(wc -l < "$removed_keys_file" | tr -d ' ')

if [[ $total_new -eq 0 && ($total_removed -eq 0 || ! $REMOVE_MISSING) ]]; then
    log_info "No changes needed"
    exit 0
fi

log_info "Found $total_new new packages"
if [[ $total_removed -gt 0 ]]; then
    if $REMOVE_MISSING; then
        log_info "Will remove $total_removed uninstalled packages"
    else
        log_warning "$total_removed packages in Brewfile are not installed (use -r to remove)"
    fi
fi

if $DRY_RUN; then
    log_info "Dry run complete - no changes made"
    exit 0
fi

# Create updated Brewfile
log_info "Writing updated Brewfile..."

# Separate new packages by type
new_taps="$TEMP_DIR/new_taps.txt"
new_brews="$TEMP_DIR/new_brews.txt"
new_casks="$TEMP_DIR/new_casks.txt"
new_mas="$TEMP_DIR/new_mas.txt"
new_vscode="$TEMP_DIR/new_vscode.txt"
new_go="$TEMP_DIR/new_go.txt"

grep '^tap ' "$new_packages_file" > "$new_taps" 2>/dev/null || true
grep '^brew ' "$new_packages_file" > "$new_brews" 2>/dev/null || true
grep '^cask ' "$new_packages_file" > "$new_casks" 2>/dev/null || true
grep '^mas ' "$new_packages_file" > "$new_mas" 2>/dev/null || true
grep '^vscode ' "$new_packages_file" > "$new_vscode" 2>/dev/null || true
grep '^go ' "$new_packages_file" > "$new_go" 2>/dev/null || true

{
    current_section=""
    added_taps=false
    added_brews=false
    added_casks=false
    added_mas=false
    added_vscode=false
    added_go=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if this is a section header comment
        if [[ "$line" =~ ^#.*[Tt]aps ]]; then
            current_section="tap"
        elif [[ "$line" =~ ^#.*CLI|^#.*brew ]]; then
            current_section="brew"
        elif [[ "$line" =~ ^#.*[Cc]ask|^#.*[Dd]esktop|^#.*[Aa]pplication ]]; then
            current_section="cask"
        elif [[ "$line" =~ ^#.*[Mm]ac.*[Aa]pp.*[Ss]tore|^#.*mas ]]; then
            current_section="mas"
        elif [[ "$line" =~ ^#.*VS.*[Cc]ode|^#.*vscode ]]; then
            current_section="vscode"
        elif [[ "$line" =~ ^#.*[Gg]o.*[Pp]ackage ]]; then
            current_section="go"
        fi

        # Check if line should be removed
        should_remove=false
        if $REMOVE_MISSING && [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ ! "$line" =~ instance_eval ]]; then
            key=$(get_package_key "$line")
            if [[ -n "$key" ]] && grep -qxF "$key" "$removed_keys_file"; then
                should_remove=true
            fi
        fi

        if ! $should_remove; then
            echo "$line"
        fi

        # Add new packages after empty lines following section headers
        if [[ -z "$line" ]]; then
            case "$current_section" in
                tap)
                    if ! $added_taps && [[ -s "$new_taps" ]]; then
                        cat "$new_taps"
                        added_taps=true
                    fi
                    ;;
                brew)
                    if ! $added_brews && [[ -s "$new_brews" ]]; then
                        cat "$new_brews"
                        added_brews=true
                    fi
                    ;;
                cask)
                    if ! $added_casks && [[ -s "$new_casks" ]]; then
                        cat "$new_casks"
                        added_casks=true
                    fi
                    ;;
                mas)
                    if ! $added_mas && [[ -s "$new_mas" ]]; then
                        cat "$new_mas"
                        added_mas=true
                    fi
                    ;;
                vscode)
                    if ! $added_vscode && [[ -s "$new_vscode" ]]; then
                        cat "$new_vscode"
                        added_vscode=true
                    fi
                    ;;
                go)
                    if ! $added_go && [[ -s "$new_go" ]]; then
                        cat "$new_go"
                        added_go=true
                    fi
                    ;;
            esac
            current_section=""
        fi
    done < "$BREWFILE"

    # Add any remaining new packages at the end
    if ! $added_taps && [[ -s "$new_taps" ]]; then
        echo ""
        echo "# Additional Taps"
        cat "$new_taps"
    fi
    if ! $added_brews && [[ -s "$new_brews" ]]; then
        echo ""
        echo "# Additional CLI Tools"
        cat "$new_brews"
    fi
    if ! $added_casks && [[ -s "$new_casks" ]]; then
        echo ""
        echo "# Additional Desktop Applications"
        cat "$new_casks"
    fi
    if ! $added_mas && [[ -s "$new_mas" ]]; then
        echo ""
        echo "# Additional Mac App Store Apps"
        cat "$new_mas"
    fi
    if ! $added_vscode && [[ -s "$new_vscode" ]]; then
        echo ""
        echo "# Additional VS Code Extensions"
        cat "$new_vscode"
    fi
    if ! $added_go && [[ -s "$new_go" ]]; then
        echo ""
        echo "# Additional Go Packages"
        cat "$new_go"
    fi
} > "$TEMP_DIR/updated.brewfile"

# Replace original file
cp "$TEMP_DIR/updated.brewfile" "$BREWFILE"

log_success "Updated $BREWFILE"
