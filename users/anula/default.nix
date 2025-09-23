{ config, pkgs, ... }:

{
  imports = [
    ./update_notifier.nix
  ];

  home.username = "anula";
  home.homeDirectory = "/home/anula";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Terminal QoL programs
    tmux
    tree
    htop
    xclip

    # Browser
    vivaldi

    # Entertainment
    spotify
  ];

  # Default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = "vivaldi-stable.desktop";
    "x-scheme-handler/http" = "vivaldi-stable.desktop";
    "x-scheme-handler/https" = "vivaldi-stable.desktop";
  };

  home.file.".config/tmux/tmux.conf" = {
    source = ./res/tmux.conf;
  };

  # Enable home-manager CLI
  programs.home-manager.enable = true;
}
