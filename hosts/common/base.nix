#
# This file defines the base configuration for any NixOS system.
#
{ config, pkgs, inputs, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_CH.UTF-8";
    LC_IDENTIFICATION = "de_CH.UTF-8";
    LC_MEASUREMENT = "de_CH.UTF-8";
    LC_MONETARY = "de_CH.UTF-8";
    LC_NAME = "de_CH.UTF-8";
    LC_NUMERIC = "de_CH.UTF-8";
    LC_PAPER = "de_CH.UTF-8";
    LC_TELEPHONE = "de_CH.UTF-8";
    LC_TIME = "de_CH.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.anula = {
    isNormalUser = true;
    description = "anula";
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    # Needed for podman
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    git
    jujutsu
    wget
    (vim-full.override {
      python3 = python3;
    })
  ];

  environment.variables.EDITOR = "vim";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  # Home manager global settings
  home-manager = {
    useGlobalPkgs = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data. It is usually set once during install.
  system.stateVersion = "25.05";
}
