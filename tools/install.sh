#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "${GREEN}Installing CLI applications from subdirectories...${NC}"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "${RED}Go is not installed. Please install Go first.${NC}"
    exit 1
fi

# Find all directories in the current location
DIRS=$(find . -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "$DIRS" ]; then
    echo "${RED}No subdirectories found to build applications from.${NC}"
    exit 1
fi

# Create bin directory if it doesn't exist
BIN_DIR="$HOME/bin"
mkdir -p "$BIN_DIR"

# Count of successfully built applications
BUILT_COUNT=0

# Function to build an application from a directory
build_app_from_dir() {
    local dir="$1"
    local app_name=$(basename "$dir")
    
    echo "${YELLOW}Processing directory: $app_name${NC}"
    
    # Check if directory contains Go files
    if [ -z "$(find "$dir" -name "*.go" | head -n 1)" ]; then
        echo "${BLUE}⚠ No Go files found in $app_name, skipping...${NC}"
        return
    fi
    
    echo "${BLUE}Building $app_name application...${NC}"
    
    # Build the application directly in its directory
    (cd "$dir" && go build -o "$app_name" .)
    
    # Check if build was successful
    if [ $? -ne 0 ]; then
        echo "${RED}✗ Failed to build $app_name${NC}"
        return
    fi
    
    # Install to user's bin directory
    if [ -f "$dir/$app_name" ]; then
        cp "$dir/$app_name" "$BIN_DIR/"
        chmod +x "$BIN_DIR/$app_name"
        echo "${GREEN}✓ Installed $app_name to $BIN_DIR/${NC}"
        BUILT_COUNT=$((BUILT_COUNT + 1))
        
        # Clean up the binary from source directory
        rm "$dir/$app_name"
    else
        echo "${RED}✗ Failed to build $app_name${NC}"
    fi
}

# Process each directory
for dir in $DIRS; do
    # Skip hidden directories
    if [[ $(basename "$dir") == .* ]]; then
        continue
    fi
    
    build_app_from_dir "$dir"
done

# Add bin directory to PATH if not already there
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "${BLUE}Adding $BIN_DIR to PATH in your shell configuration...${NC}"
    
    # Find the appropriate shell config file
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
        touch "$SHELL_CONFIG"
    fi
    
    # Add the bin directory to PATH
    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
    echo "Please restart your terminal or run 'source $SHELL_CONFIG' to update PATH."
else
    echo "$BIN_DIR is already in PATH."
fi

# List installed applications
if [ $BUILT_COUNT -gt 0 ]; then
    echo "${GREEN}Successfully installed $BUILT_COUNT CLI applications:${NC}"
    find "$BIN_DIR" -type f -executable -newer /tmp -exec basename {} \; | sort | while read app; do
        echo "- $app"
    done
    
    echo "${GREEN}Installation complete!${NC}"
    echo "You can now run these commands from your terminal."
else
    echo "${YELLOW}No applications were built or installed.${NC}"
fi