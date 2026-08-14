{
  description = "anula's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Keep inputs.nixpkgs of home-manager consistent with
      # the current flake.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      # Use stable version: https://github.com/nix-community/nixvim/issues/3699
      # Deliberately NOT following our nixpkgs here: the actual neovim
      # build already reuses the ambient/global pkgs via
      # `programs.nixvim.nixpkgs.useGlobalPackages = true` (set in
      # users/anula/neovim/default.nix - it defaults to false, this
      # isn't automatic from home-manager.useGlobalPkgs despite the
      # similar name). Following nixpkgs on this input too just bought
      # us a nixpkgs-revision-mismatch warning, not anything useful -
      # let nixvim's own flake.lock use its own tested pin instead.
    };
    nixwrap = {
      url = "github:rti/nixwrap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      # DMS's core Go binary needs go_1_26. nixos-26.05 has it, so we can
      # just follow the repo's main nixpkgs (no unstable pin needed).
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # dgop is DMS's system-monitoring backend
    # (programs.dank-material-shell.dgop.package). Its own flake, own
    # package output; also needs go_1_26, same reasoning as dms above.
    dgop = {
      url = "github:AvengeMedia/dgop";
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
