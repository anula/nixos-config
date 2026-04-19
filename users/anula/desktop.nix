{ pkgs, ... }:

{
  imports = [
    ./update_notifier.nix
  ];

  home.packages = with pkgs; [
    # Browser
    vivaldi
    
    # Entertainment
    spotify
    prismlauncher
    
    # Passmanager
    keepass
    
    # Clipboard
    xclip
  ];

  services.dropbox.enable = true;

  # Default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = "vivaldi-stable.desktop";
    "x-scheme-handler/http" = "vivaldi-stable.desktop";
    "x-scheme-handler/https" = "vivaldi-stable.desktop";
  };
}
