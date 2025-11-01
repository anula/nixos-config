{ config, pkgs, ... }:

{
  programs.podman = {
    enable = true;
    
    # This will create a user-level alias and socket for docker compatibility
    dockerCompat = true; 
  };

  home.packages = with pkgs; [
    podman-compose # For docker-compose style files
    podman-tui     # For a terminal UI
  ];
}
