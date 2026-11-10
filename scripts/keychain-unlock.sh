#!/bin/bash
#
# Unlock the macOS login keychain when it is locked, asking for the password
# on the terminal.
#
# Shells started by a server outside the GUI login session (such as herdr
# after a restart) see the login keychain locked, so keychain readers like
# pass-cli fail with "User interaction is not allowed". .zshrc runs this at
# interactive startup; once unlocked it exits after one quick probe.
#
# security reads the password from the tty itself; it is never stored here.
#
# Usage:
#   keychain-unlock                          # alias in .aliases
#   ./scripts/keychain-unlock.sh [keychain]
#   SKIP_KEYCHAIN_UNLOCK=1 zsh               # skip the startup check in .zshrc

set -uo pipefail

keychain="${1:-$HOME/Library/Keychains/login.keychain-db}"

# Read-only probe: succeeds when unlocked, exits 36 (errSecInteractionNotAllowed,
# -25308) when locked. Any other failure, such as a missing keychain, is not
# something a password can fix.
/usr/bin/security show-keychain-info "$keychain" >/dev/null 2>&1
probe=$?
if [[ "$probe" -ne 36 ]]; then
  exit 0
fi

# Never block without a terminal to read the password from.
if [[ ! -t 0 || ! -t 2 ]]; then
  exit 0
fi

# A handler (not an ignore) keeps Ctrl-C working for security while letting
# this script report the cancel instead of dying with it.
cancelled=false
trap 'cancelled=true' INT

# security prompts on the tty directly; its stderr only repeats the error.
/usr/bin/security unlock-keychain "$keychain" 2>/dev/null
status=$?
if [[ "$status" -ne 0 ]]; then
  if [[ "$cancelled" == true ]]; then
    reason="unlock cancelled"
  else
    reason="unlock failed (wrong password?)"
  fi
  printf '\nKeychain %s; still locked. Retry with: keychain-unlock\n' "$reason" >&2
fi
exit "$status"
