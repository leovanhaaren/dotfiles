{ pkgs, ... }:

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

  # Authenticate sudo (darwin-rebuild switch included) with Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Fonts moved from Homebrew casks (Brewfile.base font-* entries).
  fonts.packages = with pkgs; [
    fira-code
    iosevka-bin
    meslo-lgs-nf # font-meslo-for-powerlevel10k
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Used for backwards compatibility; read the nix-darwin changelog
  # before changing.
  system.stateVersion = 6;
}
