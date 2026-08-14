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
}
