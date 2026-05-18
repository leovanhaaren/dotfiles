#!/bin/bash

# Move Homebrew to an external SSD using an APFS volume + automount via LaunchDaemon.
#
# Prerequisites:
#   - External SSD formatted as APFS (GUID Partition Table with an APFS container)
#   - Homebrew installed at /opt/homebrew
#
# Usage:
#   sudo ./install/homebrew-ssd.sh [OPTIONS]
#
# Options:
#   -c, --container   APFS container identifier (find with: diskutil apfs list)
#   -n, --dry-run     Show what would be done without making changes
#   -h, --help        Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Configuration
VOLUME_NAME="Homebrew"
MOUNT_POINT="/opt/homebrew"
MOUNT_SCRIPT="/usr/local/bin/mount-homebrew.sh"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.homebrew.mount.plist"
CONTAINER=""
DRY_RUN=false

usage() {
    echo "Usage: sudo $0 [OPTIONS]"
    echo ""
    echo "Move Homebrew to an external SSD using an APFS volume + automount."
    echo ""
    echo "Options:"
    echo "  -c, --container   APFS container identifier (e.g. disk5)"
    echo "  -n, --dry-run     Show what would be done without making changes"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Find your container with: diskutil apfs list"
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

run() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] $*"
    else
        "$@"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--container)
            CONTAINER="$2"
            shift 2
            ;;
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

# Verify running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run with sudo"
    exit 1
fi

# Verify container is set
if [ -z "$CONTAINER" ]; then
    log_error "Container identifier is required. Use -c to specify it."
    echo ""
    echo "Available APFS containers:"
    diskutil apfs list 2>/dev/null | grep "Container" | head -10
    echo ""
    echo "Usage: sudo $0 -c disk5"
    exit 1
fi

# Verify container exists
if ! diskutil info "$CONTAINER" &>/dev/null; then
    log_error "Container '$CONTAINER' not found"
    exit 1
fi

# Verify Homebrew is installed at the mount point
if [ ! -x "$MOUNT_POINT/bin/brew" ]; then
    log_error "Homebrew not found at $MOUNT_POINT/bin/brew"
    exit 1
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
else
    echo "=== Moving Homebrew to external SSD ==="
fi
echo ""

# Step 1: Create APFS volume
log_info "Creating APFS volume '$VOLUME_NAME' on $CONTAINER..."
if diskutil info "/Volumes/$VOLUME_NAME" &>/dev/null; then
    log_warn "Volume '$VOLUME_NAME' already exists, skipping creation"
else
    run diskutil apfs addVolume "$CONTAINER" APFS "$VOLUME_NAME"
fi

# Step 2: Copy Homebrew to the new volume
log_info "Copying Homebrew to /Volumes/$VOLUME_NAME (this may take a while)..."
run cp -a "$MOUNT_POINT/" "/Volumes/$VOLUME_NAME/"

# Step 3: Verify the copy
log_info "Verifying the copy..."
if [ "$DRY_RUN" = false ]; then
    "/Volumes/$VOLUME_NAME/bin/brew" doctor || true
fi

# Step 4: Get volume UUID
log_info "Getting volume UUID..."
VOLUME_UUID=$(diskutil info "/Volumes/$VOLUME_NAME" | awk -F: '/Volume UUID/ {gsub(/^[ \t]+/, "", $2); print $2}')
if [ -z "$VOLUME_UUID" ]; then
    log_error "Failed to get volume UUID"
    exit 1
fi
log_info "Volume UUID: $VOLUME_UUID"

# Step 5: Back up the original Homebrew
log_info "Backing up original Homebrew to ${MOUNT_POINT}.bak..."
if [ -d "${MOUNT_POINT}.bak" ]; then
    log_warn "Backup already exists at ${MOUNT_POINT}.bak, skipping"
else
    run mv "$MOUNT_POINT" "${MOUNT_POINT}.bak"
fi

# Step 6: Mount volume at /opt/homebrew
log_info "Mounting volume at $MOUNT_POINT..."
DISK_ID=$(diskutil info "/Volumes/$VOLUME_NAME" | awk -F: '/Device Identifier/ {gsub(/^[ \t]+/, "", $2); print $2}')
run mkdir -p "$MOUNT_POINT"
run diskutil unmount "/Volumes/$VOLUME_NAME"
run diskutil mount -mountPoint "$MOUNT_POINT" "$DISK_ID"

# Step 6b: Enable ownership on volume
log_info "Enabling ownership on volume..."
run diskutil enableOwnership "$DISK_ID"

# Step 7: Create automount script
# The script waits for the external disk to be detected (up to 60s), then
# unmounts the volume if macOS auto-mounted it at /Volumes/Homebrew before
# re-mounting it at /opt/homebrew.
log_info "Creating automount script at $MOUNT_SCRIPT..."
run mkdir -p "$(dirname "$MOUNT_SCRIPT")"
if [ "$DRY_RUN" = false ]; then
    cat > "$MOUNT_SCRIPT" << SCRIPT
#!/bin/bash
UUID="$VOLUME_UUID"

# Wait for the external disk to appear (up to 60 seconds)
for i in \$(seq 1 60); do
    VOLUME=\$(/usr/sbin/diskutil info "\$UUID" 2>/dev/null | awk -F: '/Device Identifier/ {gsub(/^[ \t]+/, "", \$2); print \$2}')
    [ -n "\$VOLUME" ] && break
    sleep 1
done

[ -z "\$VOLUME" ] && exit 1

# Unmount if macOS auto-mounted it elsewhere (e.g. /Volumes/$VOLUME_NAME)
CURRENT_MOUNT=\$(/usr/sbin/diskutil info "\$UUID" | awk -F: '/Mount Point/ {gsub(/^[ \t]+/, "", \$2); print \$2}')
if [ -n "\$CURRENT_MOUNT" ] && [ "\$CURRENT_MOUNT" != "$MOUNT_POINT" ]; then
    /usr/sbin/diskutil unmount "\$VOLUME"
fi

/usr/sbin/diskutil mount -mountPoint $MOUNT_POINT "\$VOLUME"

# Enable ownership on the volume
/usr/sbin/diskutil enableOwnership "\$VOLUME"

# Ensure HOMEBREW_TEMP exists on local disk (hdiutil cannot attach DMGs from external SSD)
/bin/mkdir -p /tmp/homebrew
SCRIPT
    chmod +x "$MOUNT_SCRIPT"
else
    log_info "[DRY-RUN] Would write mount script to $MOUNT_SCRIPT"
fi

# Step 8: Create LaunchDaemon for automount on boot
log_info "Creating LaunchDaemon at $LAUNCH_DAEMON..."
if [ "$DRY_RUN" = false ]; then
    cat > "$LAUNCH_DAEMON" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.homebrew.mount</string>
    <key>ProgramArguments</key>
    <array>
        <string>$MOUNT_SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
else
    log_info "[DRY-RUN] Would write LaunchDaemon to $LAUNCH_DAEMON"
fi

# Step 9: Set HOMEBREW_TEMP to local disk
# hdiutil cannot attach DMGs from an external SSD volume, so HOMEBREW_TEMP
# must point to a local filesystem path instead of /opt/homebrew/tmp.
log_info "Creating HOMEBREW_TEMP directory at /tmp/homebrew..."
run mkdir -p /tmp/homebrew

# Step 10: Verify
log_info "Verifying Homebrew installation..."
if [ "$DRY_RUN" = false ]; then
    brew doctor || true
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Run without -n to apply changes ==="
else
    echo "=== Homebrew moved to external SSD ==="
    echo ""
    echo "Next steps:"
    echo "  1. Reboot to test the automount"
    echo "  2. After confirming it works, remove the backup:"
    echo "     sudo rm -rf ${MOUNT_POINT}.bak"
fi
