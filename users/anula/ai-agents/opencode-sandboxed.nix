{ pkgs, lib, ... }:
let 
  version = "1.1.12";
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };
  
  # Fetch the pre-built binary from GitHub Releases
  opencode-pinned = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-eiFuBbT1Grz1UBrGfg22z2AdCvE/6441vLVDD6L9DgE=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
    ];

    installPhase = ''
      mkdir -p $out/bin $out/opt/opencode
      cp -r . $out/opt/opencode/

      if [ -x "./opencode" ] && [ ! -d "./opencode" ]; then
        ln -s $out/opt/opencode/opencode $out/bin/opencode
      elif [ -x "./bin/opencode" ]; then
        ln -s $out/opt/opencode/bin/opencode $out/bin/opencode
      else
        BINARY=$(find . -maxdepth 3 -type f -executable -name "opencode" | head -n 1)
        if [ -n "$BINARY" ]; then
          ln -s $out/opt/opencode/"$BINARY" $out/bin/opencode
        else
          echo "Could not find an executable named 'opencode'."
          ls -R
          exit 1
        fi
      fi
    '';
  };

  opencode-sandboxed = makeSandbox {
    name = "opencode-sandboxed";
    binPath = "${opencode-pinned}/bin/opencode";
  };
in
{
  home.packages = [ opencode-sandboxed ];
}