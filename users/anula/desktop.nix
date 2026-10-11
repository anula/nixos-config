{ pkgs, inputs, ... }:

let
  # Point-release bumps of binary-blob apps like this one aren't
  # backported onto our pinned nixpkgs branch, so our pin regularly lags
  # upstream. Pull just this package from nixpkgs-unstable (flake.nix)
  # instead of bumping the whole system's nixpkgs for it.
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
  bitwig-studio = pkgs-unstable.bitwig-studio;
in

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

    # 3D modelling
    blender

    # Graphics
    inkscape

    # Music production
    bitwig-studio

    # Home design
    #
    # Java3D/JOGL's GLX rendering crashes under niri: NVIDIA's driver
    # mishandles GL surface reconfiguration whenever xwayland-satellite
    # resizes/hides the window (column switch, workspace switch, even
    # while floating) - open upstream bugs, no real fix:
    #   https://forums.developer.nvidia.com/t/bad-resizing-of-wayland-opengl-and-also-vulkan-subwindows-with-nvidia-drivers-any/347050
    #   https://github.com/Supreeeme/xwayland-satellite/issues/192
    # Falling back to Mesa's software GLX (llvmpipe) avoids NVIDIA's GLX
    # entirely, sidestepping the bug at the cost of 3D-view performance.
    # Scoped to niri only (detected via $NIRI_SOCKET, which niri sets for
    # its session) so a plain Xorg/Plasma session still gets hardware
    # acceleration.
    (symlinkJoin {
      name = "sweethome3d";
      paths = [ sweethome3d.application ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/sweethome3d \
          --run '
            if [ -n "$NIRI_SOCKET" ]; then
              export __GLX_VENDOR_LIBRARY_NAME=mesa
              export LIBGL_ALWAYS_SOFTWARE=1
            fi
          '
      '';
    })
    
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
