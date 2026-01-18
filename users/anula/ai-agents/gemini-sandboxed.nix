{ pkgs, lib, ... }:
let 
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  gemini-pinned = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.24.0";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-PqftnXy7pOY7teBHXzVH1mMECnximQwyYvgxqPH/Ulw=";
    };
    npmFlags = [ "--install-links" ];
    makeCacheWritable = true;
    dontCheckForBrokenSymlinks = true;

    npmDepsHash = "sha256-1hHPXYgeinK7SxF9yvQBCHYO7H1htnED3ot7wFzHDn0=";

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
