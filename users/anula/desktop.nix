{ pkgs, ... }:

{
  imports = [
    ./update_notifier.nix
  ];

  home.packages = with pkgs; [
    # Browser
    # Forced onto X11 (via xwayland-satellite) instead of native Wayland:
    # Chromium's native-Wayland fractional-scale-v1 client implementation
    # has an interop bug with niri specifically - at our monitor's 1.5
    # output scale, Vivaldi renders everything ~huge, while KDE/Qt apps
    # (Konsole) and Steam are unaffected at the same scale, so this isn't
    # niri or our scale config being wrong. --ozone-platform=x11 sidesteps
    # Chromium's Wayland path entirely, scaled once by Xwayland instead -
    # confirmed to fix it. NIXOS_OZONE_WL would otherwise push vivaldi
    # onto native Wayland automatically (see nixpkgs' vivaldi wrapper).
    (vivaldi.override { commandLineArgs = "--ozone-platform=x11"; })

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
