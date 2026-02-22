{ pkgs, lib, ... }:
let 
  makeSandbox = import ./ai-agent-sandbox.nix { inherit pkgs; };

  gemini-pinned = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.29.5";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-+gFSTq0CXMZa2OhP2gOuWa5WtteKW7Ys78lgnz7J72g=";
    };
    npmFlags = [ "--install-links" ];
    makeCacheWritable = true;
    dontCheckForBrokenSymlinks = true;

    npmDepsHash = "sha256-RGiWtJkLFV1UfFahHPzxtzJIsPCseEwfSsPdLfBkavI=";

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
