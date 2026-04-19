#
# This file defines the desktop-related configuration for a NixOS system.
#
{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure KDE Plasma Desktop Environment with Wayland.
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}
