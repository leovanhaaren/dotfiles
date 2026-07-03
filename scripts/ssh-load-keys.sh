#!/bin/bash
#
# Load SSH private keys from Proton Pass into the macOS Keychain-backed SSH
# agent.
#
# Fetches private keys via the Proton Pass CLI (pass-cli) and loads them into
# the macOS Keychain-backed agent.
#
# Prerequisites:
#   - Proton Pass CLI (pass-cli) installed and logged in
#   - macOS with Keychain-backed SSH agent
#
# Usage:
#   ./scripts/ssh-load-keys.sh
#   ./scripts/ssh-load-keys.sh --if-empty --quiet
#   SSH_AUTH_SOCK=/path/to/agent.sock ./scripts/ssh-load-keys.sh

set -euo pipefail

quiet=false
if_empty=false

usage() {
  cat <<'EOF'
Usage: ssh-load-keys.sh [--if-empty] [--quiet]

Options:
  --if-empty  Skip loading when the SSH agent already has keys.
  --quiet     Suppress normal output.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --if-empty)
      if_empty=true
      ;;
    -q|--quiet)
      quiet=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

log() {
  if [[ "$quiet" != true ]]; then
    echo "$@"
  fi
}

# Resolve SSH agent socket.
#
# Supports callers passing SSH_AUTH_SOCK explicitly, and falls back to the
# macOS launchd-managed agent socket when SSH_AUTH_SOCK is missing from the
# current shell environment.
if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)"
  export SSH_AUTH_SOCK
fi

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  echo "Error: SSH_AUTH_SOCK is not set" >&2
  echo "Start an ssh-agent or export SSH_AUTH_SOCK before running this script." >&2
  exit 1
fi

if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
  echo "Error: SSH_AUTH_SOCK does not point to a socket: $SSH_AUTH_SOCK" >&2
  exit 1
fi

if [[ "$if_empty" == true ]] && ssh-add -l >/dev/null 2>&1; then
  log "SSH agent already has keys; skipping Proton Pass load."
  exit 0
fi

# Load SSH keys from Proton Pass directly into the configured agent
log ""
log "=== Proton Pass ==="
log "Using SSH agent: $SSH_AUTH_SOCK"
log "Loading SSH keys via pass-cli..."
pass-cli ssh-agent load
log "✓ Proton Pass keys loaded"

log ""
log "Done. Loaded keys:"
if [[ "$quiet" == true ]]; then
  ssh-add -l >/dev/null 2>&1 || true
else
  ssh-add -l
fi
