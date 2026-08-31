# user and home come from the host entry in flake.nix (specialArgs).
{ user, home, ... }:

{
  imports = [ ./homebrew.nix ./defaults.nix ];

  # Determinate Nix manages the daemon and nix.conf itself.
  nix.enable = false;

  # User owning user-scoped options (Homebrew, defaults).
  system.primaryUser = user;

  users.users.${user} = {
    name = user;
    inherit home;
  };

  programs.zsh.enable = true;

  # Used for backwards compatibility; read the nix-darwin changelog
  # before changing.
  system.stateVersion = 6;
}
