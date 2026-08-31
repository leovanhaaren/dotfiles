{
  description = "Declarative macOS configuration (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew }: {
    darwinConfigurations."MacBook-Pro-van-Leo" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/macbook.nix
        ./modules/darwin
        nix-homebrew.darwinModules.nix-homebrew
        {
          # Install Homebrew itself declaratively; adopt an existing
          # installation in place (Cellar and casks stay untouched).
          # Taps stay mutable: brew bundle manages them as before.
          nix-homebrew = {
            enable = true;
            user = "l.vanhaaren";
            autoMigrate = true;
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          # On first activation, existing Stow symlinks at the same
          # targets are renamed aside instead of failing the switch.
          home-manager.backupFileExtension = "hm-backup";
          home-manager.useUserPackages = true;
          home-manager.users."l.vanhaaren" = import ./modules/home;
        }
      ];
    };
  };
}
