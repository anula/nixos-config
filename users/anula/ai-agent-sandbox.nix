{ pkgs }:

# A shared wrapper to sandbox AI agents (like gemini-cli and opencode) 
# using bubblewrap.
#
# Arguments:
# - name: The name of the resulting script (e.g., "gemini-sandboxed").
# - binPath: The full path to the executable to run inside the sandbox.
# - configDirName: (Optional) The name of the directory in ~/.config to bind 
#                  to home. Defaults to 'name'.

{ name, binPath, configDirName ? name }:
pkgs.writeShellScriptBin name ''
  #!${pkgs.bash}/bin/bash
  set -e

  if [ -z "$1" ]; then
    echo "Error: You must specify a directory to sandbox."
    echo "Usage: ${name} /path/to/your/directory [arguments...]"
    exit 1
  fi

  WORKDIR="$1"
  # Discard the first command line arg.
  shift

  PERSISTENT_CONFIG_DIR="$HOME/.config/${configDirName}"
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
    --ro-bind ${pkgs.gnutar}/bin/tar /bin/tar \
    --ro-bind ${pkgs.findutils}/bin/find /bin/find \
    --bind "$WORKDIR" /work \
    --bind "$PERSISTENT_CONFIG_DIR" /home/sandboxuser \
    --chdir /work \
    --setenv NODE_EXTRA_CA_CERTS ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
    --setenv SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
    --setenv HOME /home/sandboxuser \
    --setenv SHELL /bin/bash \
    --setenv EDITOR /bin/vim \
    --setenv PATH "/bin" \
    ${binPath} "$@"
''
