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
      # SDDM remembers whichever session you last logged into
      # (/var/lib/sddm/state.conf) and reuses it on every subsequent
      # boot, silently overriding defaultSession below. Turn that off
      # so defaultSession is actually authoritative.
      settings.General.RememberLastSession = false;
    };
    defaultSession = "niri";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Unlocks a secret-service store via PAM at SDDM login (same
  # login-password auto-unlock KWallet gets under Plasma). Needed for
  # niri, which has no keyring daemon of its own - without this,
  # Chromium-based apps (e.g. Vivaldi) fail to open their password store.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
}
