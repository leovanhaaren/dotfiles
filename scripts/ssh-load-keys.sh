#!/bin/bash
#
# Load SSH private keys from 1Password and Proton Pass into the macOS
# Keychain-backed SSH agent.
#
# Fetches private keys via the 1Password CLI (op) and Proton Pass CLI
# (pass-cli), converts PKCS#8 keys to OpenSSH format if needed, loads them
# into the macOS Keychain-backed agent, and securely removes the temp files.
#
# Prerequisites:
#   - 1Password CLI (op) installed and signed in
#   - Proton Pass CLI (pass-cli) installed and logged in
#   - python3 (for PKCS#8 to OpenSSH conversion)
#   - macOS with Keychain-backed SSH agent
#
# Usage:
#   ./scripts/ssh-load-keys.sh

set -euo pipefail

# Format: "op_item_title:op_account:local_key_name:label"
OP_KEYS=(
  "SSH Key leovhaaren@gmail.com:my.1password.eu:id_leovanhaaren:Personal GitHub (auth)"
  "SSH Key leovhaaren+signing@gmail.com:my.1password.eu:id_leovanhaaren_signing:Personal GitHub (signing)"
  "Github Authentication key:ksyos.1password.com:id_leo_ksyos:Ksyos GitHub (auth)"
  "Github Signing key:ksyos.1password.com:id_leo_ksyos_signing:Ksyos GitHub (signing)"
)

# Convert a PKCS#8 ed25519 private key (BEGIN PRIVATE KEY) to OpenSSH format.
# ssh-add only accepts OpenSSH format, but 1Password sometimes exports PKCS#8.
pkcs8_to_openssh() {
  python3 -c "
import base64, struct, os, sys

pem = sys.stdin.read()
lines = [l for l in pem.strip().split('\n') if not l.startswith('-----')]
der = base64.b64decode(''.join(lines))
raw_private = der[16:48]
raw_public = der[51:83]

def ssh_string(data):
    return struct.pack('>I', len(data)) + data

check = os.urandom(4)
check_int = struct.unpack('>I', check)[0]
key_type = b'ssh-ed25519'
pubkey_blob = ssh_string(key_type) + ssh_string(raw_public)
priv = struct.pack('>II', check_int, check_int)
priv += ssh_string(key_type) + ssh_string(raw_public)
priv += ssh_string(raw_private + raw_public) + ssh_string(b'')
pad = 8 - (len(priv) % 8)
if pad < 8:
    priv += bytes(range(1, pad + 1))
blob = b'openssh-key-v1\x00' + ssh_string(b'none') + ssh_string(b'none')
blob += ssh_string(b'') + struct.pack('>I', 1) + ssh_string(pubkey_blob) + ssh_string(priv)
encoded = base64.b64encode(blob).decode()
print('-----BEGIN OPENSSH PRIVATE KEY-----')
for i in range(0, len(encoded), 70):
    print(encoded[i:i+70])
print('-----END OPENSSH PRIVATE KEY-----')
"
}

# Fetch a key from 1Password via the op CLI.
fetch_from_op() {
  local op_title="$1" op_account="$2"
  op item get "$op_title" --account "$op_account" --fields label=private_key --format json \
    | jq -r '.value'
}

# Load SSH keys from Proton Pass directly into the system agent
echo ""
echo "=== Proton Pass ==="
echo "Loading SSH keys via pass-cli..."
pass-cli ssh-agent load
echo "✓ Proton Pass keys loaded"

# Load SSH keys from 1Password
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for entry in "${OP_KEYS[@]}"; do
  IFS=':' read -r op_title op_account key_name label <<< "$entry"
  temp_key="$TEMP_DIR/$key_name"

  echo ""
  echo "=== $label ==="
  echo "Fetching from 1Password ($op_account)..."
  fetch_from_op "$op_title" "$op_account" > "$temp_key"

  # Convert PKCS#8 to OpenSSH format if needed (ssh-add only accepts OpenSSH)
  if head -1 "$temp_key" | grep -q "BEGIN PRIVATE KEY"; then
    pkcs8_to_openssh < "$temp_key" > "$temp_key.converted"
    mv "$temp_key.converted" "$temp_key"
  fi

  chmod 600 "$temp_key"
  ssh-add --apple-use-keychain "$temp_key"
  rm -f "$temp_key"

  echo "✓ $label loaded into macOS Keychain"
done

echo ""
echo "Done. Loaded keys:"
ssh-add -l
