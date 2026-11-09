#!/usr/bin/env bash
# pnpm tokenHelper for GitHub Packages (@ksyos). Prints the token on stdout.
#
# pnpm runs this for every command, from any shell, hook, IDE, or `mise exec`, so
# the token is read from a macOS login keychain cache and refreshed from Proton
# Pass (through pass-run.sh) when it is missing or older than the TTL. A stale
# cached token is still used if Proton Pass is unavailable.
#
# Wire it up in the machine-local ~/.npmrc (pnpm requires an absolute path):
#   //npm.pkg.github.com/:tokenHelper=/absolute/path/to/scripts/pnpm-token-helper.sh
#
# Usage: pnpm-token-helper.sh [--refresh]   (--refresh re-fetches, e.g. after rotation)
# Without a token it prints a placeholder, so only registry requests fail.
# Environment:
#   NPM_AUTH_TOKEN                  printed as-is when set (CI or explicit override)
#   PNPM_TOKEN_PASS_REF             Proton Pass reference to the token
#   PNPM_TOKEN_KEYCHAIN_SERVICE     keychain service of the cache (default: dotfiles)
#   PNPM_TOKEN_TTL_SECONDS          cache lifetime (default: 86400)
set -euo pipefail

if [[ -n "${NPM_AUTH_TOKEN:-}" && "${1:-}" != --refresh ]]; then
  printf '%s\n' "$NPM_AUTH_TOKEN"
  exit 0
fi

pass_ref="${PNPM_TOKEN_PASS_REF:-pass://Agents/KSYOS_GITHUB_PACKAGES_TOKEN/API Key}"
service="${PNPM_TOKEN_KEYCHAIN_SERVICE:-dotfiles}"
account=NPM_AUTH_TOKEN
ttl="${PNPM_TOKEN_TTL_SECONDS:-86400}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cached="$(security find-generic-password -s "$service" -a "$account" -w 2>/dev/null || true)"

cache_age() {
  local mdat
  mdat="$(security find-generic-password -s "$service" -a "$account" 2>/dev/null |
    sed -n 's/.*"mdat"<timedate>=0x[0-9A-F]*  *"\([0-9]\{14\}\)Z.*/\1/p')"
  [[ -n "$mdat" ]] || { echo "$ttl"; return; }
  echo $(( $(date -u +%s) - $(date -u -j -f %Y%m%d%H%M%S "$mdat" +%s) ))
}

if [[ -n "$cached" && "${1:-}" != --refresh ]] && (( $(cache_age) < ttl )); then
  printf '%s\n' "$cached"
  exit 0
fi

# shellcheck disable=SC2016 # expanded by the child shell that pass-cli run injects into
if fresh="$(PASS_RUN_NO_MASKING=1 "$script_dir/pass-run.sh" NPM_AUTH_TOKEN="$pass_ref" \
  -- /bin/sh -c 'printf "%s" "$NPM_AUTH_TOKEN"' 2>/dev/null)" && [[ "$fresh" =~ ^[A-Za-z0-9_]+$ ]]; then
  # Feed the token through stdin so it never appears in a process argument list.
  printf 'add-generic-password -U -s %s -a %s -w %s\n' "$service" "$account" "$fresh" | security -i >/dev/null 2>&1 ||
    echo "${0##*/}: could not cache the token in the keychain" >&2
  printf '%s\n' "$fresh"
  exit 0
fi

if [[ -n "$cached" ]]; then
  echo "${0##*/}: Proton Pass lookup failed; using the cached token" >&2
  printf '%s\n' "$cached"
  exit 0
fi

# pnpm runs this helper even for commands that never reach the registry (scripts,
# git hooks), and fails them when it exits non-zero or prints nothing. Print a
# placeholder instead so only registry requests fail, with a 401.
echo "${0##*/}: no cached token and the Proton Pass lookup of $pass_ref failed; registry requests will fail until: ${0##*/} --refresh" >&2
printf '%s\n' unavailable
