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
     # Don't follow nixpkgs: https://github.com/nix-community/nixvim/issues/3699
     inputs.nixpkgs.follows = "nixpkgs";
   };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, ... }@inputs: {
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
    };
  };
}
