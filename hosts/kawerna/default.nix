#
# This file defines the specific configuration for the 'kawerna' host.
#
{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  # Set the hostname for this machine.
  networking.hostName = "kawerna";
}
