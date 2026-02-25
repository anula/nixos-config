{ pkgs, lib, ... }:
let 
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  gemini-pinned = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.33.1";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-dDP+UcIuajyad0tZz6/jqJ9AMERUtyn0z2ohkGiSSj0=";
    };
    npmFlags = [ "--install-links" ];
    makeCacheWritable = true;
    dontCheckForBrokenSymlinks = true;

    npmDepsHash = "sha256-Frne1xZoMqcJowMzhGrBpTYcjqQuUgbP2ak63NYbHlY=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libsecret ];

    dontNpmBuild = true;
  };

  gemini-sandboxed = makeSandbox {
    name = "gemini-sandboxed";
    binPath = "${gemini-pinned}/bin/gemini";
  };
in
{
  home.packages = [ gemini-sandboxed ];
}
