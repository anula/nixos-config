{ pkgs, lib, ... }:
let 
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  gemini-pinned = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.23.0";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-tl9Iy1M0YxPvUpbIQRl7/P2iRIb5n1cvHEqK2k3OR5I=";
    };
    npmFlags = [ "--install-links" ];
    makeCacheWritable = true;
    dontCheckForBrokenSymlinks = true;

    npmDepsHash = "sha256-gPmH/Ym6+UxbpH8CEuDmdZtbR6HqWPjMchs1zlDELDU=";

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