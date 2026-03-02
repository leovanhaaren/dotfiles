#!/bin/bash
#
# Load SSH private keys from 1Password into the macOS Keychain-backed SSH agent.
#
# Usage:
#   1. Run this script
#   2. For each key, paste the private key when prompted (copy from 1Password)
#   3. The key is added to macOS Keychain and the temp file is securely removed
#
# After running, you can comment out the IdentityAgent lines in ~/.ssh/config
# to use the macOS agent instead of the 1Password agent.

set -euo pipefail

KEYS=(
  "id_leovanhaaren:Personal GitHub (auth)"
  "id_leovanhaaren_signing:Personal GitHub (signing)"
  "id_leo_ksyos:Ksyos GitHub (auth)"
  "id_leo_ksyos_signing:Ksyos GitHub (signing)"
)

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for entry in "${KEYS[@]}"; do
  key_name="${entry%%:*}"
  label="${entry##*:}"
  temp_key="$TEMP_DIR/$key_name"

  echo ""
  echo "=== $label ($key_name) ==="
  echo "In 1Password: find the key → right-click → 'Copy Private Key'"
  echo "Then paste it here and press Enter, followed by Ctrl+D:"
  echo ""

  cat > "$temp_key"
  chmod 600 "$temp_key"

  ssh-add --apple-use-keychain "$temp_key"
  rm -f "$temp_key"

  echo "✓ $label loaded into macOS Keychain"
done

echo ""
echo "Done. Loaded keys:"
ssh-add -l
