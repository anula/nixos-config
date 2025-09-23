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

  # Enable home-manager CLI
  programs.home-manager.enable = true;

  # =======================
  # vvv Update notifier vvv

  systemd.user.services.flake-update-check = {
    Unit = {
      Description = "Check for Nix flake updates";
    };

    Service = {
      Type = "oneshot";
      # Provides nix and the notify-send command
      ExecStart = pkgs.writeShellScript "flake-update-check" ''
        set -euo pipefail

        FLAKE_DIR="${config.home.homeDirectory}/.nixos-config"
        cd "$FLAKE_DIR"

        # Check for updates without modifying the lock file.
        if ! ${pkgs.nix}/bin/nix flake update --output-lock-file /dev/null &> /dev/null; then
          ${pkgs.libnotify}/bin/notify-send \
            "New updates available" \
            "Run 'nix flake update' and 'switch' the result to apply." \
            --icon=update-high --app-name "Updates available!" -t 0
        fi
      '';
    };
  };

  systemd.user.timers.flake-update-check = {
    Unit = {
      Description = "Timer to check for Nix flake updates";
    };

    Timer = {
      # Every 6 hours.
      OnCalendar = "0/6:00";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # ^^^ Update notifier ^^^
  # =======================
}
