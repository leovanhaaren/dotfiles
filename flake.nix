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

  outputs = { self, nixpkgs, nix-darwin, home-manager }:
    let
      # One entry per machine; the attribute name must match one of
      # the host's names (LocalHostName, HostName, or ComputerName)
      # so `darwin-rebuild switch --flake .` and install.sh resolve
      # it automatically. User and home differ per machine.
      hosts = {
        "MacBook-Pro-van-Leo" = {
          module = ./hosts/macbook.nix;
          user = "l.vanhaaren";
          home = "/Users/l.vanhaaren";
        };
        "leo-mac-mini" = {
          module = ./hosts/mac-mini.nix;
          user = "leo";
          home = "/Volumes/SSD/leo";
        };
      };

      mkHost = { module, user, home }: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit user home; };
        modules = [
          module
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # On first activation, existing Stow symlinks at the same
            # targets are renamed aside instead of failing the switch.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.useUserPackages = true;
            home-manager.users.${user} = import ./modules/home;
          }
        ];
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs (_: mkHost) hosts;
    };
}
