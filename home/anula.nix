{ config, pkgs, ... }:

{
  home.username = "anula";
  home.homeDirectory = "/home/anula";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Terminal QoL programs
    tmux
    tree
    htop

    # Browser
    vivaldi

    # Entertainment
    spotify
  ];

  # Enable home-manager CLI
  programs.home-manager.enable = true;
}
