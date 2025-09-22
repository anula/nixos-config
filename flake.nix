{
  description = "anula's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      kawerna = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/kawerna/default.nix
        ];
      };
    };
  };
}
