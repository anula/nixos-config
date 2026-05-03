{ pkgs, ... }:

let
  # Pin Talosctl version here
  talosVersion = "1.13.0";
  talosSrc = pkgs.fetchurl {
    url = "https://github.com/siderolabs/talos/releases/download/v${talosVersion}/talosctl-linux-amd64";
    # To get the SHA256:
    # nix-prefetch-url https://github.com/siderolabs/talos/releases/download/v${talosVersion}/talosctl-linux-amd64
    sha256 = "1biv8yld4p4jmbr0fynwsimwrc0zs9yzv2rm7cd8r2vh3hcwv9aa";
  };

  talosctl-pinned = pkgs.runCommand "talosctl" { } ''
    mkdir -p $out/bin
    cp ${talosSrc} $out/bin/talosctl
    chmod +x $out/bin/talosctl
  '';
in
{
  home.packages = with pkgs; [
    fluxcd
    kubectl
    kubernetes-helm
    kustomize
    talosctl-pinned
  ];
}
