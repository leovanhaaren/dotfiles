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

set -euo pipefail

# Load SSH keys from Proton Pass directly into the system agent
echo ""
echo "=== Proton Pass ==="
echo "Loading SSH keys via pass-cli..."
pass-cli ssh-agent load
echo "✓ Proton Pass keys loaded"

echo ""
echo "Done. Loaded keys:"
ssh-add -l
