#!/usr/bin/env bash
# filepath: /Users/leo/Workspaces/leovanhaaren/dotfiles/install.sh

# Set up symlinks from dotfiles to home directory
# Excludes files that start with a dot, and uses exclusions from config.yaml

echo "Setting up symlinks from dotfiles to home directory..."

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to config.yaml file
CONFIG_FILE="$DOTFILES_DIR/config.yaml"

# User's home directory
HOME_DIR="$HOME"

# Check if yaml command (yq) is available
if ! command -v yq &> /dev/null; then
    echo "Warning: 'yq' command not found. Installing with Homebrew..."
    brew install yq || { echo "Error: Failed to install yq. Please install it manually."; exit 1; }
fi

# Read excludes from config.yaml
EXCLUDES=()
if [ -f "$CONFIG_FILE" ]; then
    # Use yq to extract excludes array
    while IFS= read -r pattern; do
        EXCLUDES+=("$pattern")
    done < <(yq '.excludes[]' "$CONFIG_FILE")
    
    echo "Excluded patterns from config.yaml: ${EXCLUDES[*]}"
else
    echo "Warning: config.yaml not found. No exclusions loaded."
fi

# Add standard exclusions
EXCLUDES+=(".*" "install.sh" "config.yaml")

# Echo the final list of exclusions
echo "Final exclusion patterns: ${EXCLUDES[*]}"

# Create exclusion pattern for find command
FIND_EXCLUDE=""
for item in "${EXCLUDES[@]}"; do
    # Handle glob patterns by converting them to -name patterns
    if [[ "$item" == *"*"* ]]; then
        FIND_EXCLUDE="$FIND_EXCLUDE -not -name \"$item\""
    else
        FIND_EXCLUDE="$FIND_EXCLUDE -not -path \"*/$item\" -not -name \"$item\""
    fi
done

# Find all files in the root directory that don't match exclusion patterns
# and don't start with a dot
find_command="find \"$DOTFILES_DIR\" -maxdepth 1 -type f -not -path \"*/\\.*\" $FIND_EXCLUDE"
files=$(eval "$find_command")

# Create symlinks
for file in $files; do
    filename=$(basename "$file")
    target="$HOME_DIR/.$filename"
    
    # Check if target already exists
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            echo "Link already exists: $target"
        else
            echo "Warning: $target already exists but is not a symlink"
        fi
    else
        echo "Creating symlink: $file → $target"
        ln -s "$file" "$target"
    fi
done

# Handle directories in config.yaml, if specified
if yq -e '.directories' "$CONFIG_FILE" &>/dev/null; then
    echo "Processing directories..."
    while IFS= read -r dir_path; do
        if [ -d "$DOTFILES_DIR/$dir_path" ]; then
            target_dir="$HOME_DIR/.$dir_path"
            echo "Creating directory symlink: $DOTFILES_DIR/$dir_path → $target_dir"
            
            # Create parent directory if needed
            mkdir -p "$(dirname "$target_dir")"
            
            # Create symlink for the directory
            if [ -e "$target_dir" ]; then
                if [ -L "$target_dir" ]; then
                    echo "Directory link already exists: $target_dir"
                else
                    echo "Warning: $target_dir already exists but is not a symlink"
                fi
            else
                ln -s "$DOTFILES_DIR/$dir_path" "$target_dir"
            fi
        else
            echo "Warning: Directory not found: $DOTFILES_DIR/$dir_path"
        fi
    done < <(yq '.directories[]' "$CONFIG_FILE" 2>/dev/null)
fi

echo "Symlink setup complete!"

# Read local_extensions from config.yaml using yq
echo "Reading local extensions from config.yaml..."
local_extensions=()
if [ -f "$CONFIG_FILE" ] && yq -e '.local_extensions' "$CONFIG_FILE" &>/dev/null; then
    # Use yq to extract local_extensions array
    while IFS= read -r file; do
        local_extensions+=("$file")
    done < <(yq '.local_extensions[]' "$CONFIG_FILE")
    
    echo "Found local extensions: ${local_extensions[*]}"
else
    echo "No local extensions found in config.yaml."
fi

# Create each file if it doesn't exist
echo "Checking and creating local extension files..."
for file in "${local_extensions[@]}"; do
  target_file="$HOME_DIR/$file"
  
  if [ ! -f "$target_file" ]; then
    echo "Creating $target_file"
    mkdir -p "$(dirname "$target_file")"
    touch "$target_file"
    echo "# Your local $file configuration" > "$target_file"
  else
    echo "$target_file already exists, skipping"
  fi
done

echo "Done! Local extension files have been created if they didn't exist."