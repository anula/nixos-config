#
# This file defines the specific configuration for the 'kawerna' host.
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
    ../common/desktop.nix
    ../common/niri.nix
    ../common/audio.nix
    ../common/bare-metal.nix
    ./3dprinting.nix
    ./displaylink.nix
    ./graphics.nix
    ./hardware-configuration.nix
    ./kdeprograms.nix
    ./printer.nix
  ];

  # Set the hostname for this machine.
  networking.hostName = "kawerna";

  # Home Manager configuration
  home-manager.users.anula = {
    imports = [
      inputs.nixvim.homeModules.nixvim
      # inputs.niri.homeModules.config is intentionally NOT imported here:
      # inputs.niri.nixosModules.niri (see hosts/common/niri.nix) already
      # injects it via home-manager.sharedModules for every user once
      # home-manager is present as a NixOS module. Importing it again here
      # duplicates internal niri-flake options (programs.niri.finalConfig)
      # and fails the build with an "already declared" error.
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
      ../../users/anula/core.nix
      ../../users/anula/dev.nix
      ../../users/anula/ai.nix
      ../../users/anula/desktop.nix
      ../../users/anula/kubernetes.nix
      ../../users/anula/niri.nix
    ];

    # dgop (DMS's system-monitoring backend) isn't in nixpkgs at all - it's
    # built from its own flake.
    #
    # NB: DMS's own "dms-shell" package and its quickshell dependency used
    # to need overriding here too (nixos-25.05 lacked go_1_26/quickshell),
    # but now that the repo's main nixpkgs is 26.05 - which has both -
    # DMS's own defaults (ambient home-manager pkgs) resolve them directly.
    programs.dank-material-shell.dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.dgop;
  };

  # Handling Steam on system level, since it needs system-level
  # stuff like drivers and firewall rules.
  programs.steam = {
    enable = true;
    # Open ports in the firewall for Steam Remote Play
    remotePlay.openFirewall = true;
    # Open ports in the firewall for Source Dedicated Server
    dedicatedServer.openFirewall = true;
    # Open ports in the firewall for Steam Local Network Game Transfers
    localNetworkGameTransfers.openFirewall = true;
  };

  services.tailscale.enable = true;

  # Podman
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to
      # each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # Sandboxing
    inputs.nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.default
    podman-compose

    gcloud-with-components
    ansible

    # App indicators
    libappindicator-gtk3

    calibre
  ];

  # =================
  # vvv Bluetooth vvv

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  # KDE has its own Bluetooth manager.
  services.blueman.enable = false;

  # ^^^ Bluetooth ^^^
  # =================
}
