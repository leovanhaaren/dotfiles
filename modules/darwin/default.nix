{ ... }:

{
  imports = [ ./homebrew.nix ];

  # Determinate Nix manages the daemon and nix.conf itself.
  nix.enable = false;

  # User owning user-scoped options (Homebrew, defaults).
  system.primaryUser = "l.vanhaaren";

  users.users."l.vanhaaren" = {
    name = "l.vanhaaren";
    home = "/Users/l.vanhaaren";
  };

  programs.zsh.enable = true;

  # Used for backwards compatibility; read the nix-darwin changelog
  # before changing.
  system.stateVersion = 6;
}
