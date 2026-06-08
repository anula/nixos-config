{ pkgs, lib, ... }:
let
  version = "1.0.6";
  hash = "sha512-G1eXe+CDmLA0TvUBkIloPAqumClUXN8wVsmh0CuUnqmNtuZD75bvT2h3ZU9NSNUmcDXviidlKo4CP2W5HAbfdg==";

  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  agy-pkg = pkgs.stdenv.mkDerivation {
    pname = "agy";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-6458082025406464/linux-x64/cli_linux_x64.tar.gz";
      inherit hash;
    };

    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp antigravity $out/bin/agy
      chmod +x $out/bin/agy
    '';
  };

  agy-sandboxed = makeSandbox {
    name = "agy-sandboxed";
    binPath = "${agy-pkg}/bin/agy";
    configDirName = "agy";
  };
in
{
  home.packages = [ agy-sandboxed ];
}
