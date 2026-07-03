# Auto-load SSH keys from Proton Pass into the current SSH agent.
# Best-effort only: never block or fail shell startup.
if status is-interactive
    set -l ssh_load_keys "$HOME/Workspaces/leovanhaaren/dotfiles/scripts/ssh-load-keys.sh"

    if test -x "$ssh_load_keys"; and command -q pass-cli; and command -q ssh-add
        "$ssh_load_keys" --if-empty --quiet </dev/null >/dev/null 2>&1; or true
    end
end
