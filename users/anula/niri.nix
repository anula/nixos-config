#
# Home Manager configuration for niri + DankMaterialShell (Dank Linux).
#
# Keybinds and startup config live here as Nix (programs.niri.settings)
# rather than a raw config.kdl dotfile, so:
#   - it's type-checked and validated at build time (niri-flake generates
#     and lints the resulting config.kdl during `nixos-rebuild`)
#   - DankMaterialShell's own niri module can merge its binds in
#     declaratively (see `programs.dank-material-shell.niri` below)
#
# niri ships NO default keybinds of its own - anything not listed here
# simply won't be bound. The binds block below is a full, faithful port
# of niri's own upstream default-config.kdl, so muscle memory from a
# stock niri install carries over 1:1. Source (pinned to the exact
# niri-stable version in hosts/common/niri.nix, v25.08 - NOT main, whose
# default config can be ahead of what's actually built/available here):
# https://github.com/YaLTeR/niri/blob/v25.08/resources/default-config.kdl
#
# A handful of upstream default keys are deliberately NOT ported, because
# DankMaterialShell's niri.enableKeybinds (see bottom of this file) claims
# them for its own IPC-driven equivalents (nicer OSDs, its own lock
# screen, etc). Nix option merging errors ("defined multiple times") if
# both sides bind the same key, so these are DMS's exclusively:
#   Super+Alt+L (lock), Mod+Comma (was consume-window-into-column),
#   XF86AudioRaiseVolume/LowerVolume/Mute/MicMute,
#   XF86MonBrightnessUp/Down, Mod+V (was toggle-window-floating, moved to
#   Mod+Shift+Space below), Mod+M (claimed by DMS's process-list panel
#   since enableSystemMonitoring is on - nothing of upstream's is lost
#   here: `maximize-window-to-edges` isn't bound to Mod+M, or to anything,
#   in niri v25.08 - the version pinned as niri-stable in
#   hosts/common/niri.nix - it was only added to niri's default config
#   later, on a newer/unstable version).
# Source: https://github.com/AvengeMedia/DankMaterialShell/blob/stable/distro/nix/niri.nix
#
# NOTE: this file assumes `programs.niri.settings` and
# `programs.dank-material-shell` are already provided - the former via
# hosts/common/niri.nix (niri's NixOS module auto-injects its home-manager
# config module), the latter via
# inputs.dms.homeModules.{dank-material-shell,niri} in
# hosts/kawerna/default.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.konsole # Mod+T
    playerctl # media keys
    # No swaylock/brightnessctl here: DMS's own niri keybinds (below) own
    # locking and brightness via its own IPC/OSD instead.
    # No app launcher here either: DMS's own Mod+Space covers that (see
    # niri.enableKeybinds below) - fuzzel/Mod+D was dropped as redundant.

    # Spectacle (from Plasma) doesn't work under niri - it needs a
    # running kwin to talk to over D-Bus. This is the niri-ecosystem
    # equivalent: grim captures, slurp is the drag-to-select-an-area
    # picker, swappy is the actual GUI (shown after selection - lets you
    # annotate/crop, then save or copy). Launchable via the app launcher
    # (see xdg.desktopEntries.screenshot below) rather than a keybind.
    grim
    slurp
    swappy
  ];

  # Makes the grim+slurp+swappy combo above show up in the app launcher
  # (e.g. DMS's Mod+Space) as a normal entry, same as Spectacle would.
  xdg.desktopEntries.screenshot = {
    name = "Screenshot";
    genericName = "Screenshot Tool";
    comment = "Select an area of the screen to capture and annotate";
    icon = "camera-photo";
    exec = "${pkgs.writeShellScript "screenshot-select" ''
      ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
    ''}";
    terminal = false;
    categories = [ "Graphics" "Utility" ];
    settings.Keywords = "screenshot;capture;snip;snapshot;";
  };

  # Hides Spectacle from the launcher under niri, where it's broken (see
  # note above) and would otherwise sit right next to the working
  # replacement above, failing silently if clicked. Still shows and
  # works normally under Plasma.
  #
  # Shadows its real entry (org.kde.spectacle.desktop, id/fields
  # confirmed against KDE's own source) with a copy restricted to
  # OnlyShowIn=KDE. This works because ~/.local/share/applications -
  # where home-manager's xdg.desktopEntries writes to - takes precedence
  # over the system one in XDG_DATA_DIRS lookup order. Only loses the
  # upstream file's translations and the right-click quick-capture
  # actions (full screen/window/region/record shortcuts) under Plasma -
  # cosmetic.
  xdg.desktopEntries."org.kde.spectacle" = {
    name = "Spectacle";
    genericName = "Screenshot Capture Utility";
    comment = "Take screenshots and screen recordings";
    icon = "spectacle";
    exec = "spectacle";
    terminal = false;
    categories = [ "Qt" "KDE" "Utility" ];
    settings = {
      Keywords = "snapshot;capture;print;screenshot;snipping;snipping tool;snip;";
      OnlyShowIn = "KDE;";
    };
  };

  programs.niri.settings = {
    input.keyboard.xkb = {
      # Comma-separated = multiple layouts; "options" below binds the key
      # that cycles between them. Alt+Shift, not a Mod-based combo, since
      # Mod+Space is already DMS's launcher and most other Mod+<key>
      # combos are claimed by niri binds above.
      layout = "us,pl";
      options = "grp:alt_shift_toggle";
    };

    binds = {
      # Mod-Shift-/ (usually Mod-?) shows a list of important hotkeys.
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };

      # Suggested binds for running programs: terminal, screen locker.
      # (App launcher is Mod+Space, from DMS - see niri.enableKeybinds
      # below - so no niri-side launcher bind here.)
      "Mod+T" = {
        hotkey-overlay.title = "Open a Terminal: konsole";
        action.spawn = "konsole";
      };
      # Super+Alt+L (lock screen) is bound by DMS instead - see bottom of file.

      # Screen-reader toggle (escape hatch, works even when locked).
      "Super+Alt+S" = {
        allow-when-locked = true;
        hotkey-overlay.hidden = true;
        action.spawn-sh = "pkill orca || exec orca";
      };

      # Volume/mic keys are bound by DMS instead (its own OSD) - see bottom
      # of file.

      # Media keys (any MPRIS player, via playerctl).
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl play-pause";
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl play-pause";
      };
      "XF86AudioStop" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl stop";
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl previous";
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl next";
      };

      # Brightness keys are bound by DMS instead (its own OSD) - see bottom
      # of file.

      # Overview (zoomed-out view of workspaces/windows).
      "Mod+O" = {
        repeat = false;
        action.toggle-overview = { };
      };

      "Mod+Q" = {
        repeat = false;
        action.close-window = { };
      };

      # Focus movement: arrows + vim-style hjkl, both bound.
      "Mod+Left".action.focus-column-left = { };
      "Mod+Down".action.focus-window-down = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+L".action.focus-column-right = { };

      # Move window/column with focus.
      "Mod+Ctrl+Left".action.move-column-left = { };
      "Mod+Ctrl+Down".action.move-window-down = { };
      "Mod+Ctrl+Up".action.move-window-up = { };
      "Mod+Ctrl+Right".action.move-column-right = { };
      "Mod+Ctrl+H".action.move-column-left = { };
      "Mod+Ctrl+J".action.move-window-down = { };
      "Mod+Ctrl+K".action.move-window-up = { };
      "Mod+Ctrl+L".action.move-column-right = { };

      "Mod+Home".action.focus-column-first = { };
      "Mod+End".action.focus-column-last = { };
      "Mod+Ctrl+Home".action.move-column-to-first = { };
      "Mod+Ctrl+End".action.move-column-to-last = { };

      # Monitor focus/move.
      "Mod+Shift+Left".action.focus-monitor-left = { };
      "Mod+Shift+Down".action.focus-monitor-down = { };
      "Mod+Shift+Up".action.focus-monitor-up = { };
      "Mod+Shift+Right".action.focus-monitor-right = { };
      "Mod+Shift+H".action.focus-monitor-left = { };
      "Mod+Shift+J".action.focus-monitor-down = { };
      "Mod+Shift+K".action.focus-monitor-up = { };
      "Mod+Shift+L".action.focus-monitor-right = { };

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

      # Workspace up/down (by direction).
      "Mod+Page_Down".action.focus-workspace-down = { };
      "Mod+Page_Up".action.focus-workspace-up = { };
      "Mod+U".action.focus-workspace-down = { };
      "Mod+I".action.focus-workspace-up = { };
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
      "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

      "Mod+Shift+Page_Down".action.move-workspace-down = { };
      "Mod+Shift+Page_Up".action.move-workspace-up = { };
      "Mod+Shift+U".action.move-workspace-down = { };
      "Mod+Shift+I".action.move-workspace-up = { };

      # Mouse wheel: workspace switching (rate-limited via cooldown-ms).
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = { };
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = { };
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = { };
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = { };
      };

      # Mouse wheel: column focus/move.
      "Mod+WheelScrollRight".action.focus-column-right = { };
      "Mod+WheelScrollLeft".action.focus-column-left = { };
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

      # Shift+wheel mirrors the "horizontal scroll via shift" convention.
      "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
      "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

      # Workspaces by index (dynamic workspace system - see niri docs).
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      # Consume/expel a window into/out of the focused column.
      # (Mod+Comma/consume-window-into-column is skipped: DMS uses that
      # key for its settings toggle. consume-or-expel below covers the
      # same ground.)
      "Mod+BracketLeft".action.consume-or-expel-window-left = { };
      "Mod+BracketRight".action.consume-or-expel-window-right = { };
      "Mod+Period".action.expel-window-from-column = { };

      # Column/window sizing.
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.switch-preset-window-height = { };
      "Mod+Ctrl+R".action.reset-window-height = { };
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };
      # No Mod+M/Mod+Shift+M bind here: DMS claims Mod+M for its process
      # list (enableSystemMonitoring is on below), and upstream's
      # maximize-window-to-edges isn't available to move elsewhere - see
      # the note near the top of this file.
      "Mod+Ctrl+F".action.expand-column-to-available-width = { };
      "Mod+C".action.center-column = { };
      "Mod+Ctrl+C".action.center-visible-columns = { };
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      # Floating layout.
      # Moved from upstream's Mod+V: DMS uses that key for its clipboard
      # manager toggle.
      "Mod+Shift+Space".action.toggle-window-floating = { };
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };

      # Tabbed column display.
      "Mod+W".action.toggle-column-tabbed-display = { };

      # Screenshots (niri's built-in screenshot UI - no external tool needed).
      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };

      # Escape hatch for remote-desktop/KVM clients that inhibit shortcuts.
      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = { };
      };

      "Mod+Shift+E".action.quit = { };
      "Ctrl+Alt+Delete".action.quit = { };

      "Mod+Shift+P".action.power-off-monitors = { };
    };

    spawn-at-startup = [
      { argv = [ "xwayland-satellite" ]; }
      # niri's own upstream default also spawns a status bar (waybar) here;
      # skipped, since DankMaterialShell's panel replaces it (see
      # programs.dank-material-shell.niri.enableSpawn below).
    ];
  };

  programs.dank-material-shell = {
    enable = true;
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;

    # DMS injects its own niri binds (launcher, shell toggle, notification
    # center, etc.) and startup spawn declaratively via these two flags,
    # merged into the binds set above (see the note near the top of this
    # file for which upstream keys DMS claims and how they were resolved).
    # Don't also enable `systemd.enable` - that would spawn a 2nd instance.
    niri = {
      enableKeybinds = true;
      enableSpawn = true;
      # DMS's alternate mechanism for merging keybinds (via config file
      # `include`s instead of the typed `binds` option above). Off,
      # since enableKeybinds already covers this more directly - DMS
      # itself warns against combining the two.
      includes.enable = false;
    };
  };
}
