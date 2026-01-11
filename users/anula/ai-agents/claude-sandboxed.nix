{ pkgs, lib, ... }:
let
  version = "2.1.4";
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  # Stage 1: Fetch and Install Dependencies (Fixed-Output Derivation)
  # This step fetches the source and runs 'npm install'. 
  # It has network access but cannot reference /nix/store paths in its output.
  claude-assets = pkgs.stdenv.mkDerivation {
    pname = "claude-code-assets";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-gRHD9KvVjP8vTnfwj1oyaRm7ZbICapiF+53/os2L13E="; 
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.nodejs_22 pkgs.cacert pkgs.git ];

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-wSXFNbvsag1LKq+iZUdaASqOl0WBtLH93xNjeuERkms=";

    installPhase = ''
      export HOME=$TMPDIR
      
      mkdir -p $out
      tar -xzf $src -C $out --strip-components=1
      
      cd $out
      npm install --production --no-save --ignore-scripts
      
      # Optional: Remove any build artifacts that might reference /nix/store
      rm -rf $out/.npm
    '';
  };

  # Stage 2: Create the Executable (Standard Derivation)
  # This step takes the assets and wraps them with the system Node.js.
  claude-code-pkg = pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;
    
    phases = [ "installPhase" ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
      
      # Copy the assets from Stage 1
      cp -r ${claude-assets}/* $out/lib/node_modules/@anthropic-ai/claude-code/

      mkdir -p $out/bin
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/claude \
        --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
        --set CLAUDE_CODE_DISABLE_UPDATE_CHECK 1
    '';

    meta = with lib; {
      description = "Claude Code CLI";
      homepage = "https://www.anthropic.com";
      license = licenses.unfree;
      mainProgram = "claude";
    };
  };

  claude-sandboxed = makeSandbox {
    name = "claude-sandboxed";
    binPath = "${claude-code-pkg}/bin/claude";
  };
in
{
  home.packages = [ claude-sandboxed ];
}
