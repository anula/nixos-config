{
  description = "anula's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # Keep inputs.nixpkgs of home-manager consistent with
      # the current flake.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      # Use stable version: https://github.com/nix-community/nixvim/issues/3699
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixwrap = {
      url = "github:rti/nixwrap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, nixwrap, nixos-wsl, ... }@inputs: {
    nixosConfigurations = {
      kawerna = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # nix-community modules
          home-manager.nixosModules.home-manager

          # custom modules
          ./hosts/kawerna/default.nix
        ];
      };

      lufcik = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          nixos-wsl.nixosModules.default

          ./hosts/lufcik/default.nix
        ];
      };
    };
  };
}
