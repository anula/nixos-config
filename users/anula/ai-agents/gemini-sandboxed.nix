{ pkgs, lib, ... }:
let 
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  gemini-pinned = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.38.1";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-Iq/KxQ8rbLtXDbGzcZxspfFwar189H3mBWwOD4hO7HU=";
    };
    npmFlags = [ "--install-links" ];
    makeCacheWritable = true;
    dontCheckForBrokenSymlinks = true;

    npmDepsHash = "sha256-T3fxNFvkLR7f49GQjzzTnl3VM+VUUgJfFF5d2GGe7L4=";

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
