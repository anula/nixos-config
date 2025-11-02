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
    ../common.nix
    ./displaylink.nix
    ./graphics.nix
    ./hardware-configuration.nix
    ./kdeprograms.nix
    ./printer.nix
  ];

  # Set the hostname for this machine.
  networking.hostName = "kawerna";

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
    inputs.nixwrap.packages.${system}.default
    podman-compose

    gcloud-with-components
    ansible

    # App indicators
    libappindicator-gtk3
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
