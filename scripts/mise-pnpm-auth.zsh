# Inject the GitHub Packages token only for direct mise exec/x pnpm commands.
# Source after `mise activate zsh` to preserve mise's shell integration.
if (( ${+functions[mise]} )) && [[ ${functions[mise]} != ${functions[_mise_pnpm_auth]:-} ]]; then
  functions[_mise_pnpm_original]=${functions[mise]}
fi

_mise_pnpm_auth() {
  local arg
  local after_separator=0
  if [[ "$1" == exec || "$1" == x ]]; then
    for arg in "$@"; do
      if (( after_separator )); then
        if [[ "$arg" == pnpm ]]; then
          "$DOTFILES_DIR/scripts/pass-run.sh" \
            NPM_AUTH_TOKEN='pass://Agents/KSYOS_GITHUB_PACKAGES_TOKEN/API Key' \
            -- mise "$@"
          return $?
        fi
        break
      fi
      [[ "$arg" == -- ]] && after_separator=1
    done
  fi

  if (( ${+functions[_mise_pnpm_original]} )); then
    _mise_pnpm_original "$@"
  else
    command mise "$@"
  fi
}

functions[mise]=${functions[_mise_pnpm_auth]}
