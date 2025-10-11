#
# This file defines the specific configuration for the 'kawerna' host.
#
{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
    ./displaylink.nix
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

  # ================
  # vvv Graphics vvv
  # Lots based on https://nixos.wiki/wiki/Nvidia

  # Enable OpenGL
  hardware.graphics = {
    enable = true;

    # Might be needed for some Steam games.
    enable32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    # Driver for NVIDIA's video decoding engine
    # For hardware acceleration
    nvidia-vaapi-driver
    # An utility to check if acceleration is working
    libva-utils
  ];

  # ^^^ Graphics ^^^
  # ================

}
