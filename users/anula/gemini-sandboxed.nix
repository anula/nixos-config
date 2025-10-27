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

{ pkgs, lib, ... }:
let 
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
      --ro-bind ${pkgs.coreutils}/bin/stat /bin/stat \
      --ro-bind ${pkgs.coreutils}/bin/date /bin/date \
      --ro-bind ${pkgs.coreutils}/bin/sort /bin/sort \
      --ro-bind ${pkgs.coreutils}/bin/uniq /bin/uniq \
      --ro-bind ${pkgs.jj}/bin/jj /bin/jj \
      --bind "$WORKDIR" /work \
      --bind "$PERSISTENT_CONFIG_DIR" /home/sandboxuser \
      --chdir /work \
      --setenv NODE_EXTRA_CA_CERTS ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      --setenv HOME /home/sandboxuser \
      --setenv EDITOR /bin/vim \
      --setenv PATH "/bin" \
      ${pkgs.gemini-cli}/bin/gemini "$@"
  '';
in
{
  home.packages = [ gemini-sandboxed ];
}
