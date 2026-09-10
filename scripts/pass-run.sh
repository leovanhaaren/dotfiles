#!/usr/bin/env bash
# Run a command with secrets resolved from Proton Pass through `pass-cli run`.
#
# Each leading VAR=pass://... argument is exported as a secret reference; pass-cli
# resolves the references inside the child process and masks them on stdout and
# stderr, so the plaintext never enters this shell, `ps`, or history.
#
# Prefers a scoped, audited Proton Pass agent session (default agent "herdr") when
# PROTON_PASS_PERSONAL_ACCESS_TOKEN is present or stored in the macOS keychain;
# otherwise uses the caller's own pass-cli session.
#
# Usage: pass-run.sh VAR=pass://VAULT/ITEM/FIELD [VAR2=pass://...] -- <command> [args...]
#   pass-run.sh NPM_AUTH_TOKEN='pass://Agents/KSYOS_GITHUB_PACKAGES_TOKEN/API Key' -- mise exec -- pnpm install
#   pass-run.sh JIRA_API_TOKEN='pass://Agents/Jira API/API Key' -- jira issue list
# Environment:
#   PROTON_PASS_PERSONAL_ACCESS_TOKEN  agent PAT; enables the agent session
#   PROTON_PASS_AGENT_KEYCHAIN_SERVICE keychain service holding the PAT when the env var is unset
#                                      (default: dot-ai-proton-pass, written by herdr/plugins/proton-agent)
#   PROTON_PASS_AGENT_NAME             agent name for the isolated session dir (default: herdr)
#   PROTON_PASS_AGENT_REASON           audit reason recorded by Proton Pass (default below)
#   PROTON_PASS_SESSION_DIR            override the isolated agent session directory
set -euo pipefail

usage() {
  echo "usage: ${0##*/} VAR=pass://VAULT/ITEM/FIELD [VAR2=pass://...] -- <command> [args...]" >&2
  exit 2
}

command -v pass-cli >/dev/null 2>&1 || { echo "pass-cli is not installed; see https://protonpass.github.io/pass-cli/" >&2; exit 127; }

# pass-cli run resolves every pass:// reference in the environment. The caller's
# shell may carry references the agent is not allowed to read (for example other
# vaults), which would fail the whole command, so drop them before adding ours.
while IFS='=' read -r name _; do
  unset "$name"
done < <(env | grep -E '^[A-Za-z_][A-Za-z0-9_]*=pass://' || true)

refs=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --) shift; break ;;
    [A-Za-z_]*=pass://*)
      export "$1"
      refs+=("${1%%=*}")
      shift
      ;;
    *=*) echo "${0##*/}: '${1%%=*}' must be a pass:// secret reference, not a literal value" >&2; exit 2 ;;
    *) usage ;;
  esac
done
[[ $# -gt 0 && ${#refs[@]} -gt 0 ]] || usage

agent_name="${PROTON_PASS_AGENT_NAME:-herdr}"
keychain_service="${PROTON_PASS_AGENT_KEYCHAIN_SERVICE:-dot-ai-proton-pass}"
export PROTON_PASS_AGENT_REASON="${PROTON_PASS_AGENT_REASON:-Resolve ${refs[*]} for ${1##*/}}"

# The herdr proton-agent plugin stores the agent token in the macOS keychain.
if [[ -z "${PROTON_PASS_PERSONAL_ACCESS_TOKEN:-}" ]] && command -v security >/dev/null 2>&1; then
  if keychain_token="$(security find-generic-password -s "$keychain_service" -a "$agent_name" -w 2>/dev/null)" && [[ -n "$keychain_token" ]]; then
    export PROTON_PASS_PERSONAL_ACCESS_TOKEN="$keychain_token"
  fi
  unset keychain_token
fi

if [[ -n "${PROTON_PASS_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  export PROTON_PASS_SESSION_DIR="${PROTON_PASS_SESSION_DIR:-${TMPDIR:-/tmp}/pass-agent-${agent_name}}"
  mkdir -p "$PROTON_PASS_SESSION_DIR"
  chmod 700 "$PROTON_PASS_SESSION_DIR"
  if ! pass-cli info >/dev/null 2>&1; then
    pass-cli logout --force >/dev/null 2>&1 || true
    if ! pass-cli login >/dev/null; then
      echo "Proton Pass agent login failed for agent '${agent_name}'; renew the token with: pass-cli agent renew ${agent_name} --expiration 1m" >&2
      exit 1
    fi
  fi
elif ! pass-cli info >/dev/null 2>&1; then
  echo "No Proton Pass session. Either export PROTON_PASS_PERSONAL_ACCESS_TOKEN for agent '${agent_name}' or run: pass-cli login" >&2
  exit 1
fi

exec pass-cli run -- "$@"
