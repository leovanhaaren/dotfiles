#!/bin/bash

# Move Homebrew to an external SSD using an APFS volume and a LaunchDaemon.
# With --provision, prepare an empty mounted volume on a fresh machine
# instead (nix-homebrew or the Homebrew installer then installs into it).
# The command is a dry run unless --apply is provided.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

VOLUME_NAME="Homebrew"
MOUNT_POINT="/opt/homebrew"
MOUNT_SCRIPT="/usr/local/bin/mount-homebrew.sh"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.homebrew.mount.plist"
TEMP_ROOT="/private/var/db/homebrew"
TEMP_DIR="$TEMP_ROOT/tmp"
CONTAINER=""
DRY_RUN=true
ALREADY_MIGRATED=false
BACKUP_CREATED=false
MOUNT_COMPLETE=false
PERSISTENCE_TOUCHED=false
MOUNT_SCRIPT_EXISTED=false
LAUNCH_DAEMON_EXISTED=false
MOUNT_SCRIPT_BACKUP="${MOUNT_SCRIPT}.dotfiles-backup.$$"
LAUNCH_DAEMON_BACKUP="${LAUNCH_DAEMON}.dotfiles-backup.$$"
MOUNT_SCRIPT_NEW="${MOUNT_SCRIPT}.new.$$"
LAUNCH_DAEMON_NEW="${LAUNCH_DAEMON}.new.$$"
DISK_ID=""
BREW_USER="${SUDO_USER:-${USER:-}}"
PROVISION=false

usage() {
    echo "Usage: sudo $0 --container <disk> [--apply]"
    echo ""
    echo "Options:"
    echo "  -c, --container   APFS container identifier (for example disk5)"
    echo "  --provision       Prepare an empty volume on a fresh machine (no copy)"
    echo "  --apply           Apply the migration"
    echo "  -n, --dry-run     Show the migration plan without changes (default)"
    echo "  -h, --help        Show this help message"
    exit 0
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

normalize_disk() {
    printf '%s\n' "${1#/dev/}"
}

disk_field() {
    local target="$1"
    local field="$2"
    diskutil info "$target" 2>/dev/null | awk -F: -v field="$field" '$1 ~ "^[[:space:]]*" field "$" {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

run() {
    if [ "$DRY_RUN" = true ]; then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

run_as_brew_user() {
    local command=("$@")
    local environment=()
    [ -d "$TEMP_DIR" ] && environment=(/usr/bin/env "HOMEBREW_TEMP=$TEMP_DIR")
    if [ "$(id -u)" -eq 0 ]; then
        /usr/bin/sudo -u "$BREW_USER" -H "${environment[@]}" "${command[@]}"
    else
        "${environment[@]}" "${command[@]}"
    fi
}

backup_persistence() {
    if [ -e "$MOUNT_SCRIPT" ] || [ -L "$MOUNT_SCRIPT" ]; then
        /bin/cp -pP "$MOUNT_SCRIPT" "$MOUNT_SCRIPT_BACKUP"
        MOUNT_SCRIPT_EXISTED=true
    fi
    if [ -e "$LAUNCH_DAEMON" ] || [ -L "$LAUNCH_DAEMON" ]; then
        /bin/cp -pP "$LAUNCH_DAEMON" "$LAUNCH_DAEMON_BACKUP"
        LAUNCH_DAEMON_EXISTED=true
    fi
    PERSISTENCE_TOUCHED=true
}

restore_persistence() {
    if [ "$PERSISTENCE_TOUCHED" = false ]; then
        return
    fi
    if [ "$MOUNT_SCRIPT_EXISTED" = true ]; then
        /bin/mv -f "$MOUNT_SCRIPT_BACKUP" "$MOUNT_SCRIPT"
    else
        /bin/rm -f "$MOUNT_SCRIPT"
    fi
    if [ "$LAUNCH_DAEMON_EXISTED" = true ]; then
        /bin/mv -f "$LAUNCH_DAEMON_BACKUP" "$LAUNCH_DAEMON"
    else
        /bin/rm -f "$LAUNCH_DAEMON"
    fi
}

cleanup_persistence_backups() {
    /bin/rm -f "$MOUNT_SCRIPT_BACKUP" "$LAUNCH_DAEMON_BACKUP" "$MOUNT_SCRIPT_NEW" "$LAUNCH_DAEMON_NEW"
}

validate_brew() {
    local brew_path="$1"
    log_info "Validating Homebrew as $BREW_USER..."
    run_as_brew_user "$brew_path" --version >/dev/null
    run_as_brew_user "$brew_path" config >/dev/null
    if ! run_as_brew_user "$brew_path" doctor; then
        log_warn "brew doctor reported diagnostics; review them separately from migration integrity"
    fi
}

rollback() {
    local exit_code=$?
    trap - ERR
    if [ "$DRY_RUN" = false ] && [ "$MOUNT_COMPLETE" = false ]; then
        restore_persistence
        if [ "$BACKUP_CREATED" = true ]; then
            log_error "Migration failed after the original Homebrew tree was moved; rolling back"
            if [ -n "$DISK_ID" ]; then
                diskutil unmount "$DISK_ID" >/dev/null 2>&1 || true
            fi
            rmdir "$MOUNT_POINT" >/dev/null 2>&1 || true
            if [ ! -e "$MOUNT_POINT" ] && [ -d "${MOUNT_POINT}.bak" ]; then
                mv "${MOUNT_POINT}.bak" "$MOUNT_POINT"
                log_warn "Restored $MOUNT_POINT from ${MOUNT_POINT}.bak"
            else
                log_error "Automatic rollback could not restore $MOUNT_POINT; backup remains at ${MOUNT_POINT}.bak"
            fi
        fi
    fi
    cleanup_persistence_backups
    exit "$exit_code"
}
trap rollback ERR

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--container)
            [ "$#" -ge 2 ] || { log_error "$1 requires a value"; exit 1; }
            CONTAINER=$(normalize_disk "$2")
            shift 2
            ;;
        --provision) PROVISION=true; shift ;;
        --apply) DRY_RUN=false; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    log_error "This migration supports macOS only"
    exit 1
fi
if [ -z "$CONTAINER" ]; then
    log_error "Container identifier is required. Find it with: diskutil apfs list"
    exit 1
fi
if ! diskutil info "$CONTAINER" >/dev/null 2>&1; then
    log_error "Container '$CONTAINER' not found"
    exit 1
fi
if [ -z "$BREW_USER" ] || [ "$BREW_USER" = "root" ]; then
    log_error "Run with sudo from the non-root account that owns Homebrew"
    exit 1
fi
if [ "$DRY_RUN" = false ] && [ "$(id -u)" -ne 0 ]; then
    log_error "Apply mode must be run with sudo"
    exit 1
fi
CURRENT_NAME=$(disk_field "$MOUNT_POINT" "Volume Name" || true)
if [ "$PROVISION" = false ] && [ ! -x "$MOUNT_POINT/bin/brew" ]; then
    log_error "Homebrew not found at $MOUNT_POINT/bin/brew"
    log_error "On a fresh machine, prepare an empty volume with --provision"
    exit 1
fi
if [ "$PROVISION" = true ] && [ -x "$MOUNT_POINT/bin/brew" ] && [ "$CURRENT_NAME" != "$VOLUME_NAME" ]; then
    log_error "Homebrew is already installed at $MOUNT_POINT; migrate it by running without --provision"
    exit 1
fi

CURRENT_CONTAINER=$(normalize_disk "$(disk_field "$MOUNT_POINT" "APFS Container" || true)")
if [ "$CURRENT_NAME" = "$VOLUME_NAME" ]; then
    if [ "$CURRENT_CONTAINER" != "$CONTAINER" ]; then
        log_error "$MOUNT_POINT is already an APFS volume from $CURRENT_CONTAINER, not requested container $CONTAINER"
        exit 1
    fi
    log_info "Homebrew is already mounted from $CONTAINER at $MOUNT_POINT"
    ALREADY_MIGRATED=true
    VOLUME_UUID=$(disk_field "$MOUNT_POINT" "Volume UUID")
    DISK_ID=$(normalize_disk "$(disk_field "$MOUNT_POINT" "Device Identifier")")
    if [ -z "$VOLUME_UUID" ] || [ -z "$DISK_ID" ]; then
        log_error "Could not resolve the mounted Homebrew volume UUID or device identifier"
        exit 1
    fi
fi

if [ "$ALREADY_MIGRATED" = false ]; then
if [ -e "${MOUNT_POINT}.bak" ]; then
    log_error "Backup already exists at ${MOUNT_POINT}.bak; resolve the previous migration before continuing"
    exit 1
fi

VOLUME_PATH="/Volumes/$VOLUME_NAME"
VOLUME_EXISTS=false
if diskutil info "$VOLUME_PATH" >/dev/null 2>&1; then
    VOLUME_EXISTS=true
    EXISTING_CONTAINER=$(normalize_disk "$(disk_field "$VOLUME_PATH" "APFS Container" || true)")
    if [ "$EXISTING_CONTAINER" != "$CONTAINER" ]; then
        log_error "$VOLUME_PATH belongs to $EXISTING_CONTAINER, not requested container $CONTAINER"
        exit 1
    fi
    UNEXPECTED_ENTRY=$(/usr/bin/find "$VOLUME_PATH" -mindepth 1 -maxdepth 1 \
        ! -name '.DocumentRevisions-V100' ! -name '.Spotlight-V100' ! -name '.Trashes' ! -name '.fseventsd' \
        -print -quit)
    if [ -n "$UNEXPECTED_ENTRY" ]; then
        log_error "Existing Homebrew volume is not empty: $UNEXPECTED_ENTRY"
        log_error "Use a newly created empty volume; existing contents are never merged"
        exit 1
    fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Homebrew SSD migration dry run ==="
elif [ "$PROVISION" = true ]; then
    echo "=== Provisioning empty Homebrew volume on external SSD ==="
else
    echo "=== Moving Homebrew to external SSD ==="
fi

if [ "$VOLUME_EXISTS" = false ]; then
    run diskutil apfs addVolume "$CONTAINER" APFS "$VOLUME_NAME"
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] The new volume UUID and device identifier will be resolved after creation"
        if [ "$PROVISION" = true ]; then
            log_info "[DRY-RUN] The empty volume will be mounted at $MOUNT_POINT with automount installed; nothing is copied"
        else
            log_info "[DRY-RUN] Homebrew will be copied, validated as $BREW_USER, mounted, and verified with rollback enabled"
        fi
        exit 0
    fi
fi

VOLUME_CONTAINER=$(normalize_disk "$(disk_field "$VOLUME_PATH" "APFS Container")")
if [ "$VOLUME_CONTAINER" != "$CONTAINER" ]; then
    log_error "Created volume belongs to $VOLUME_CONTAINER, expected $CONTAINER"
    exit 1
fi
VOLUME_UUID=$(disk_field "$VOLUME_PATH" "Volume UUID")
DISK_ID=$(normalize_disk "$(disk_field "$VOLUME_PATH" "Device Identifier")")
if [ -z "$VOLUME_UUID" ] || [ -z "$DISK_ID" ]; then
    log_error "Could not resolve the Homebrew volume UUID or device identifier"
    exit 1
fi

if [ "$PROVISION" = false ]; then
    log_info "Copying Homebrew to $VOLUME_PATH..."
    run /usr/bin/ditto "$MOUNT_POINT" "$VOLUME_PATH"
    if [ "$DRY_RUN" = false ]; then
        validate_brew "$VOLUME_PATH/bin/brew"
    fi

    log_info "Backing up the original Homebrew tree..."
    run mv "$MOUNT_POINT" "${MOUNT_POINT}.bak"
    [ "$DRY_RUN" = false ] && BACKUP_CREATED=true
fi

log_info "Mounting $DISK_ID at $MOUNT_POINT..."
run mkdir -p "$MOUNT_POINT"
run diskutil unmount "$VOLUME_PATH"
run diskutil mount -mountPoint "$MOUNT_POINT" "$DISK_ID"
run diskutil enableOwnership "$DISK_ID"

if [ "$DRY_RUN" = false ]; then
    ACTUAL_MOUNT=$(disk_field "$VOLUME_UUID" "Mount Point")
    [ "$ACTUAL_MOUNT" = "$MOUNT_POINT" ] || { log_error "Volume mounted at '$ACTUAL_MOUNT', expected $MOUNT_POINT"; false; }
fi
fi

BREW_UID=$(id -u "$BREW_USER")
BREW_GID=$(id -g "$BREW_USER")
log_info "Creating Homebrew temporary storage beneath a root-owned parent..."
if [ "$DRY_RUN" = false ]; then
    [ ! -L "$TEMP_ROOT" ] || { log_error "$TEMP_ROOT must not be a symlink"; false; }
    [ ! -e "$TEMP_ROOT" ] || [ -d "$TEMP_ROOT" ] || { log_error "$TEMP_ROOT must be a directory"; false; }
    if [ -d "$TEMP_ROOT" ]; then
        [ "$(stat -f %u "$TEMP_ROOT")" -eq 0 ] || { log_error "$TEMP_ROOT must be root-owned"; false; }
    fi
    [ ! -L "$TEMP_DIR" ] || { log_error "$TEMP_DIR must not be a symlink"; false; }
    [ ! -e "$TEMP_DIR" ] || [ -d "$TEMP_DIR" ] || { log_error "$TEMP_DIR must be a directory"; false; }
fi
run /usr/bin/install -d -o root -g wheel -m 755 "$TEMP_ROOT"
run /usr/bin/install -d -o "$BREW_UID" -g "$BREW_GID" -m 700 "$TEMP_DIR"
# In provision mode there is no brew binary yet; nix-homebrew (or the
# Homebrew installer) puts it on the mounted volume afterwards.
if [ "$DRY_RUN" = false ] && [ -x "$MOUNT_POINT/bin/brew" ]; then
    validate_brew "$MOUNT_POINT/bin/brew"
fi

log_info "Installing transactional automount files..."
run mkdir -p "$(dirname "$MOUNT_SCRIPT")"
if [ "$DRY_RUN" = false ]; then
    backup_persistence
    cat > "$MOUNT_SCRIPT_NEW" <<SCRIPT
#!/bin/bash
set -euo pipefail
UUID="$VOLUME_UUID"
MOUNT_POINT="$MOUNT_POINT"
TEMP_ROOT="$TEMP_ROOT"
TEMP_DIR="$TEMP_DIR"

for _ in \$(seq 1 60); do
    VOLUME=\$(/usr/sbin/diskutil info "\$UUID" 2>/dev/null | awk -F: '/Device Identifier/ {gsub(/^[ \t]+/, "", \$2); print \$2; exit}')
    [ -n "\${VOLUME:-}" ] && break
    sleep 1
done
[ -n "\${VOLUME:-}" ] || { /usr/bin/logger -t mount-homebrew "volume \$UUID was not detected"; exit 1; }

CURRENT_MOUNT=\$(/usr/sbin/diskutil info "\$UUID" | awk -F: '/Mount Point/ {gsub(/^[ \t]+/, "", \$2); print \$2; exit}')
if [ -n "\$CURRENT_MOUNT" ] && [ "\$CURRENT_MOUNT" != "\$MOUNT_POINT" ]; then
    /usr/sbin/diskutil unmount "\$VOLUME"
fi

/bin/mkdir -p "\$MOUNT_POINT"
/usr/sbin/diskutil mount -mountPoint "\$MOUNT_POINT" "\$VOLUME"
/usr/sbin/diskutil enableOwnership "\$VOLUME"
ACTUAL_MOUNT=\$(/usr/sbin/diskutil info "\$UUID" | awk -F: '/Mount Point/ {gsub(/^[ \t]+/, "", \$2); print \$2; exit}')
[ "\$ACTUAL_MOUNT" = "\$MOUNT_POINT" ] || { /usr/bin/logger -t mount-homebrew "mounted at \$ACTUAL_MOUNT instead of \$MOUNT_POINT"; exit 1; }

[ ! -L "\$TEMP_ROOT" ] && [ -d "\$TEMP_ROOT" ] && [ "\$(/usr/bin/stat -f %u "\$TEMP_ROOT")" -eq 0 ] || {
    /usr/bin/logger -t mount-homebrew "unsafe temporary root: \$TEMP_ROOT"
    exit 1
}
[ ! -L "\$TEMP_DIR" ] && [ -d "\$TEMP_DIR" ] || {
    /usr/bin/logger -t mount-homebrew "unsafe temporary directory: \$TEMP_DIR"
    exit 1
}
/usr/bin/install -d -o "$BREW_UID" -g "$BREW_GID" -m 700 "\$TEMP_DIR"
SCRIPT
    chmod 755 "$MOUNT_SCRIPT_NEW"

    cat > "$LAUNCH_DAEMON_NEW" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.homebrew.mount</string>
    <key>ProgramArguments</key>
    <array><string>$MOUNT_SCRIPT</string></array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/var/log/mount-homebrew.log</string>
</dict>
</plist>
PLIST
    chmod 644 "$LAUNCH_DAEMON_NEW"
    plutil -lint "$LAUNCH_DAEMON_NEW" >/dev/null
    mv "$MOUNT_SCRIPT_NEW" "$MOUNT_SCRIPT"
    mv "$LAUNCH_DAEMON_NEW" "$LAUNCH_DAEMON"
    cleanup_persistence_backups
    MOUNT_COMPLETE=true
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "=== Dry run complete. Re-run with --apply under sudo ==="
elif [ "$ALREADY_MIGRATED" = true ]; then
    echo "=== Homebrew automount files repaired ==="
elif [ "$PROVISION" = true ]; then
    echo "=== Empty Homebrew volume provisioned at $MOUNT_POINT ==="
    echo "Next: ./install.sh --nix --apply installs Homebrew onto the volume."
else
    echo "=== Homebrew moved to external SSD ==="
    echo "Backup retained at ${MOUNT_POINT}.bak until reboot verification succeeds."
fi
