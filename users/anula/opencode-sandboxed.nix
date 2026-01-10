{ pkgs, lib, ... }:
let 
  version = "1.1.12";
  
  # Fetch the pre-built binary from GitHub Releases
  opencode-pinned = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-eiFuBbT1Grz1UBrGfg22z2AdCvE/6441vLVDD6L9DgE=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
    ];

    installPhase = ''
      mkdir -p $out/bin $out/opt/opencode
      cp -r . $out/opt/opencode/

      # Try to find the real opencode binary. 
      # We avoid picking up things in node_modules if they exist.
      # If there is an 'opencode' in the root, that's usually it.
      if [ -x "./opencode" ] && [ ! -d "./opencode" ]; then
        ln -s $out/opt/opencode/opencode $out/bin/opencode
      elif [ -x "./bin/opencode" ]; then
        ln -s $out/opt/opencode/bin/opencode $out/bin/opencode
      else
        # Fallback to finding it, but prefer shorter paths (root/bin over deep nests)
        BINARY=$(find . -maxdepth 3 -type f -executable -name "opencode" | head -n 1)
        if [ -n "$BINARY" ]; then
          ln -s $out/opt/opencode/"$BINARY" $out/bin/opencode
        else
          echo "Could not find an executable named 'opencode'."
          ls -R
          exit 1
        fi
      fi
    '';
  };

  opencode-sandboxed = pkgs.writeShellScriptBin "opencode-sandboxed" ''
    #!${pkgs.bash}/bin/bash
    set -e

    if [ -z "$1" ]; then
      echo "Error: You must specify a directory to sandbox."
      echo "Usage: opencode-sandboxed /path/to/your/directory [opencode arguments...]"
      exit 1
    fi

    WORKDIR="$1"
    # Discard the first command line arg.
    shift

    # opencode will treat this as the "home", and should create the relevant
    # config dirs there.
    PERSISTENT_CONFIG_DIR="$HOME/.config/opencode-sandboxed"
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
      ${opencode-pinned}/bin/opencode "$@"
  '';
in
{
  home.packages = [ opencode-sandboxed ];
}
