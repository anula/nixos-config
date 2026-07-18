{ pkgs, lib, ... }:
let
  version = "2.1.214";
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  # Stage 1: Fetch and Install Dependencies (Fixed-Output Derivation)
  # This step fetches the source and runs 'npm install'. 
  # It has network access but cannot reference /nix/store paths in its output.
  claude-assets = pkgs.stdenv.mkDerivation {
    pname = "claude-code-assets";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-XMHrvyAKkpC0VgrZ9z1ADE2OjTMWROxF60XEcRtPY+g=";
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.nodejs_22 pkgs.cacert pkgs.git ];

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-P6pRp2Fw1gfnEYp7Fi8JpfXLHi57r2kmzAQRf/RV76w=";

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
    
    phases = [ "installPhase" "fixupPhase" ];
    dontStrip = true;

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];

    installPhase = ''
      mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
      
      # Copy the assets from Stage 1
      cp -r ${claude-assets}/* $out/lib/node_modules/@anthropic-ai/claude-code/

      mkdir -p $out/bin
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/claude \
        --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli-wrapper.cjs" \
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
