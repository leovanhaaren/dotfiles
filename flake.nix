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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }: {
    darwinConfigurations."MacBook-Pro-van-Leo" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/macbook.nix
        ./modules/darwin
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
