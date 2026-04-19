#
# This file defines the specific configuration for the 'lufcik' WSL host.
#
{ config, pkgs, inputs, ... }:

let
  gcloud-with-components = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
in
{
  imports = [
    ../common/base.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "anula";

  # Set the hostname for this machine.
  networking.hostName = "lufcik";

  # Home Manager configuration
  home-manager.users.anula = {
    imports = [
      inputs.nixvim.homeManagerModules.nixvim
      ../../users/anula/core.nix
      ../../users/anula/dev.nix
    ];
  };

  # Podman
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # Sandboxing
    inputs.nixwrap.packages.${system}.default
    podman-compose

    gcloud-with-components
    ansible
  ];
}
