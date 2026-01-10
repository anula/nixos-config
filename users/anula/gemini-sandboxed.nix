# This file defines a function that takes 'pkgs' as an argument
# and returns our sandboxed gemini package.

# bubblewrap args:
#  * --unshare-all: creates new namespaces for everything: processes (PID),
#     networking, mounts, etc.
#  * --share-net: selectively re-enables network
#  * --ro-bind /nix/store /nix/store: bind Nix store read only. Needed eg. for
#     the gemini command itself.
#  * --ro-bind /etc/resolv.conf /etc/resolv.conf: bind DNS config read-only
#  * --ro-bind /etc/passwd /etc/passwd: it needs it to get username
#  * --proc /proc and --dev /dev: are needed for proper function
#  * --bind "$WORKDIR" /work: mounts the provided dir at /work. read-write
#  * --chdir /work: changes directory into /work
#  * --setenv HOME /tmp: sets home at non-existent directory
#  * --setenv PATH "/bin": gemini-cli can only run programs in this dir. Nothing
#     by default.
#
# ============================================================================
  # HOW TO UPDATE GEMINI CLI
  # 1. Check for the latest version: https://www.npmjs.com/package/@google/gemini-cli
  # 2. Update the 'version' string below.
  # 3. Set 'hash' AND 'npmDepsHash' to lib.fakeHash (or just "sha256-0000...")
  # 4. Run the rebuild command: sudo nixos-rebuild switch --flake ~/.nixos-config#kawerna
  # 5. Nix will fail and report the correct source 'hash'. Copy/paste it.
  # 6. Run rebuild again. Nix will fail on 'npmDepsHash'. Copy/paste that one too.
  # 7. Run rebuild one last time. Success!
  # ============================================================================

{ pkgs, lib, ... }:
let 
  # Pin Gemini manually to the upstream version. See instructions up top for how
  # to update.
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

    # Tools needed *during* the build (compilers, config tools)
    nativeBuildInputs = [ pkgs.pkg-config ];

    # Libraries the code links against (libsecret is for secure storage)
    buildInputs = [ pkgs.libsecret ];

    dontNpmBuild = true;
  };
  gemini-sandboxed = pkgs.writeShellScriptBin "gemini-sandboxed" ''
    #!${pkgs.bash}/bin/bash
    set -e

    if [ -z "$1" ]; then
      echo "Error: You must specify a directory to sandbox."
      echo "Usage: gemini-sandboxed /path/to/your/directory [gemini arguments...]"
      exit 1
    fi

    WORKDIR="$1"
    # Discard the first command line arg.
    shift

    # gemini-cli will treat this as the "home", and should create the relevant
    # config dirs there (like .config and .gemini). If we want to control settings
    # we should put them in $PERSISTENT_CONFIG_DIR/.gemini/settings.json
    PERSISTENT_CONFIG_DIR="$HOME/.config/gemini-sandboxed"
    mkdir -p "$PERSISTENT_CONFIG_DIR"

    ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --ro-bind /nix/store /nix/store \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --ro-bind /etc/passwd /etc/passwd \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      --ro-bind ${pkgs.bash}/bin/bash /bin/bash \
      --ro-bind ${pkgs.bash}/bin/sh /bin/sh \
      --ro-bind ${pkgs.vim}/bin/vim /bin/vim \
      --ro-bind ${pkgs.which}/bin/which /bin/which \
      --ro-bind ${pkgs.procps}/bin/ps /bin/ps \
      --ro-bind ${pkgs.gnugrep}/bin/grep /bin/grep \
      --ro-bind ${pkgs.coreutils}/bin/ls /bin/ls \
      --ro-bind ${pkgs.coreutils}/bin/cat /bin/cat \
      --ro-bind ${pkgs.coreutils}/bin/head /bin/head \
      --ro-bind ${pkgs.coreutils}/bin/tail /bin/tail \
      --ro-bind ${pkgs.coreutils}/bin/wc /bin/wc \
      --ro-bind ${pkgs.coreutils}/bin/pwd /bin/pwd \
      --ro-bind ${pkgs.coreutils}/bin/mkdir /bin/mkdir \
      --ro-bind ${pkgs.coreutils}/bin/touch /bin/touch \
      --ro-bind ${pkgs.coreutils}/bin/echo /bin/echo \
      --ro-bind ${pkgs.coreutils}/bin/mv /bin/mv \
      --ro-bind ${pkgs.coreutils}/bin/cp /bin/cp \
      --ro-bind ${pkgs.coreutils}/bin/rm /bin/rm \
      --ro-bind ${pkgs.coreutils}/bin/stat /bin/stat \
      --ro-bind ${pkgs.coreutils}/bin/date /bin/date \
      --ro-bind ${pkgs.coreutils}/bin/sort /bin/sort \
      --ro-bind ${pkgs.coreutils}/bin/uniq /bin/uniq \
      --ro-bind ${pkgs.jj}/bin/jj /bin/jj \
      --ro-bind ${pkgs.curl}/bin/curl /bin/curl \
      --bind "$WORKDIR" /work \
      --bind "$PERSISTENT_CONFIG_DIR" /home/sandboxuser \
      --chdir /work \
      --setenv NODE_EXTRA_CA_CERTS ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      --setenv SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      --setenv HOME /home/sandboxuser \
      --setenv EDITOR /bin/vim \
      --setenv PATH "/bin" \
      ${gemini-pinned}/bin/gemini "$@"
  '';
in
{
  home.packages = [ gemini-sandboxed ];
}
