#
# This file defines configuration specific to bare-metal (physical) machines.
#
{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep only the 10 newest generations - older ones get their profile
  # entry deleted on the next switch, so they stop being a GC root.
  boot.loader.systemd-boot.configurationLimit = 10;

  # configurationLimit above only lets old generations become garbage;
  # something still has to collect them, or their store paths just sit
  # there. Weekly sweep, no age filter needed since the limit above
  # already decides what's eligible.
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    parted
    usbutils
  ];
}
