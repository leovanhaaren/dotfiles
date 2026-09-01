#!/bin/bash

managed_stow_links() {
    printf '%s\t%s\t%s\n' \
        "zshrc" "$DOTFILES/.zshrc" "$HOME/.zshrc" \
        "zprofile" "$DOTFILES/.zprofile" "$HOME/.zprofile" \
        "aliases" "$DOTFILES/.aliases" "$HOME/.aliases" \
        "functions" "$DOTFILES/.functions" "$HOME/.functions" \
        "gitconfig" "$DOTFILES/.gitconfig" "$HOME/.gitconfig" \
        "tmux.conf" "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf" \
        "gitmux.conf" "$DOTFILES/.gitmux.conf" "$HOME/.gitmux.conf" \
        "starship.toml" "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml" \
        "ghostty/config" "$DOTFILES/.config/ghostty/config" "$HOME/.config/ghostty/config" \
        "fish/config.fish" "$DOTFILES/.config/fish/config.fish" "$HOME/.config/fish/config.fish" \
        "fish/functions/wt.fish" "$DOTFILES/.config/fish/functions/wt.fish" "$HOME/.config/fish/functions/wt.fish" \
        "nvim/init.lua" "$DOTFILES/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua" \
        "nvim/lua/config/lazy.lua" "$DOTFILES/.config/nvim/lua/config/lazy.lua" "$HOME/.config/nvim/lua/config/lazy.lua" \
        "wezterm/wezterm.lua" "$DOTFILES/.config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" \
        "zed/settings.json" "$DOTFILES/.config/zed/settings.json" "$HOME/.config/zed/settings.json" \
        "sesh/sesh.toml" "$DOTFILES/.config/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml" \
        "television/config.toml" "$DOTFILES/.config/television/config.toml" "$HOME/.config/television/config.toml" \
        "television/cable/agent-sessions.toml" "$DOTFILES/.config/television/cable/agent-sessions.toml" "$HOME/.config/television/cable/agent-sessions.toml" \
        "television/cable/sesh.toml" "$DOTFILES/.config/television/cable/sesh.toml" "$HOME/.config/television/cable/sesh.toml" \
        "worktrunk/config.toml" "$DOTFILES/.config/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml" \
        "mise/config.toml" "$DOTFILES/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
}

managed_manual_links() {
    if [ "$DOTFILES" != "$HOME/dotfiles" ]; then
        printf '%s\t%s\t%s\n' "dotfiles convenience symlink" "$DOTFILES" "$HOME/dotfiles"
    fi
    printf '%s\t%s\t%s\n' \
        "ssh/config" "$DOTFILES/ssh/config.macos" "$HOME/.ssh/config" \
        "vscode/settings.json" "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    # Tracked public keys and pinned host keys (private keys stay in
    # the agent, loaded from Proton Pass by scripts/ssh-load-keys.sh).
    local ssh_file
    for ssh_file in "$DOTFILES"/ssh/*.pub "$DOTFILES/ssh/known_hosts.base"; do
        [ -f "$ssh_file" ] || continue
        printf '%s\t%s\t%s\n' "ssh/$(basename "$ssh_file")" "$ssh_file" "$HOME/.ssh/$(basename "$ssh_file")"
    done
}
