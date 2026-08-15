#
# System-level niri setup, shared across bare-metal hosts.
#
# This only enables niri as a selectable Wayland session (alongside
# whatever display manager/session the host already has, e.g. Plasma
# via SDDM in hosts/common/desktop.nix). It does not set a display
# manager itself.
#
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri.enable = true;

  programs.niri.package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable.overrideAttrs (old: {
    # niri-flake's build runs niri's cargo test suite. It already skips
    # the known-broken ::egl tests (need a real GPU), but something else
    # in there still SIGABRTs in this sandboxed nix-daemon build (a rayon
    # thread panic, not an nixpkgs/dependency-version issue) - so skip
    # tests entirely for this package rather than chase it further.
    doCheck = false;

    # nixpkgs' stock cargoInstallHook dies silently (no output, no
    # error text, reproducible with sandboxing on AND off - not a
    # resource/sandbox issue we could find) right as it starts copying
    # the already-successfully-built binary into $out. Replace it with
    # the same end result done plainly, so there's nowhere for whatever
    # this is to hide. Still runs niri's own postInstall (shell
    # completions, systemd unit, session file, docs) same as before.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      niriBin=$(find target -maxdepth 4 -type f -name niri -executable | head -n1)
      cp "$niriBin" $out/bin/

      runHook postInstall
    '';
  });

  # niri has no built-in Xwayland; this bridges X11-only apps.
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  # niri-flake auto-installs xdg-desktop-portal-gnome (it says this is
  # needed for screencasting) but doesn't pin it as niri's preferred
  # portal backend. This host also runs Plasma as an alternate SDDM
  # session (hosts/common/desktop.nix), which registers
  # xdg-desktop-portal-kde. With two default-capable backends
  # registered and no routing config, xdg-desktop-portal has no
  # deterministic way to pick one under niri. Plasma sessions are
  # unaffected by any of this (XDG_CURRENT_DESKTOP=KDE won't match the
  # "niri" key below).
  #
  # gnome is pinned as the general default, but FileChooser specifically
  # is repointed at gtk: xdg-desktop-portal-gnome doesn't implement
  # FileChooser itself outside of an actual GNOME Shell session - it
  # delegates that one interface to xdg-desktop-portal-gtk's D-Bus
  # service. Confirmed via `journalctl --user -u xdg-desktop-portal -u
  # 'xdg-desktop-portal-*'`: "Delegated FileChooser call failed: The
  # name is not activatable" - i.e. every "Choose File" dialog (e.g. in
  # Vivaldi) silently failed because that gtk service was never
  # installed, only gnome's. Installing xdg-desktop-portal-gtk here and
  # routing FileChooser to it directly fixes that.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config."niri" = {
    default = [ "gnome" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
  };
}
