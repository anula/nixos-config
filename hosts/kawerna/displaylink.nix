#
# Displaylink drivers are proprietary and depend on binary unfree blobs. They
# need to be manually added to the Nix Store unfortunately, requiring
# manual steps during the installation.
# See: https://wiki.nixos.org/wiki/Displaylink
#

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Note: this will fail before prefetching as described in file comment.
    displaylink
  ];

  boot.kernelModules = [ "evdi" ];

  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];

  systemd.services.displaylink = {
    enabled = true;
    description = "DisplayLink Manager Service";
    after = [ "display-manager.service" ];
    script = "${pkgs.displaylink}/bin/DisplayLinkManager";
    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      # This automatically restarts the service if it fails.
      Restart = "always";
      # Waits 5 seconds before trying to restart.
      RestartSec = 5;
    };
  };

  users.users.anula.extraGroups = [ "video" ];
}
