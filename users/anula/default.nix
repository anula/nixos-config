{ config, pkgs, ... }:

{
  imports = [
    ./gemini-sandboxed.nix
    ./neovim/default.nix
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

  # Persistent `nix develop` per directory 
  # See: https://github.com/nix-community/nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Note that the main editor is nvim. This is just in case.
  home.file.".vimrc" = {
    source = ./res/vimrc;
  };
  home.file.".vim/bundle/Vundle.vim" = {
    source = pkgs.vimPlugins.Vundle-vim;
    recursive = true; # Necessary because we are linking a whole directory
  };

  # Enable home-manager CLI
  programs.home-manager.enable = true;
}
