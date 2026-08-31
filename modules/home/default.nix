{ pkgs, ... }:

{
  imports = [ ./links.nix ];

  # CLI tools migrated from homebrew/Brewfile.base.
  # The Brewfile keeps these entries until the Nix binaries are
  # verified on PATH; remove them there afterwards (Phase 1 exit).
  home.packages = with pkgs; [
    air
    bat
    eza
    fd
    fish
    fzf
    gh
    git
    git-extras
    git-lfs
    glances
    go
    go-migrate
    go-tools # staticcheck
    golangci-lint
    jq
    just
    lazygit
    mise
    mosh
    neovim
    sesh
    shellcheck
    starship
    stow
    television
    tmux
    tree
    uv
    yq-go
    zoxide
  ];

  # Used for backwards compatibility; read the home-manager changelog
  # before changing.
  home.stateVersion = "25.11";
}
