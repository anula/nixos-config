{ pkgs, ... }:

let
  # Pin Talosctl version here
  talosVersion = "1.10.5";
  talosSrc = pkgs.fetchurl {
    url = "https://github.com/siderolabs/talos/releases/download/v${talosVersion}/talosctl-linux-amd64";
    # To get the SHA256:
    # nix-prefetch-url https://github.com/siderolabs/talos/releases/download/v${talosVersion}/talosctl-linux-amd64
    sha256 = "0svpa119c9cb3zp6lwqf4frba2iz8di7mbg3dqrb27s47q2rnykx";
  };

  talosctl-pinned = pkgs.runCommand "talosctl" { } ''
    mkdir -p $out/bin
    cp ${talosSrc} $out/bin/talosctl
    chmod +x $out/bin/talosctl
  '';
in
{
  home.packages = with pkgs; [
    talosctl-pinned
    kubectl
  ];
}
