{ config, pkgs, ... }:

{
  imports = [
    ./gemini-sandboxed.nix
    ./neovim/default.nix
    ./kubernetes.nix
    ./update_notifier.nix
  ];

  home.username = "anula";
  home.homeDirectory = "/home/anula";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Terminal QoL programs
    tmux
    tree
    htop
    xclip
    unzip

    # Browser
    vivaldi

    # Markdown
    glow
    (writeShellScriptBin "markserv" ''
      # npx needs node in the PATH
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec npx markserv "$@"
    '')

    # File server
    miniserve

    # Entertainment
    spotify
    prismlauncher

    # Passmanager
    keepass

    # Stuff
    restic
    bubblewrap

    # Archives
    unzip
    unar
    p7zip
    bzip2
    gzip
  ];

  services.dropbox.enable = true;

  # Default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = "vivaldi-stable.desktop";
    "x-scheme-handler/http" = "vivaldi-stable.desktop";
    "x-scheme-handler/https" = "vivaldi-stable.desktop";
  };

  home.file.".config/tmux/tmux.conf" = {
    source = ./res/tmux.conf;
  };

  home.file.".config/fancy_prompt.sh" = {
    source = ./res/fancy_prompt.sh;
  };

  # Persistent `nix develop` per directory 
  # See: https://github.com/nix-community/nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Note that the main editor is nvim. This is just in case.
  home.file.".vimrc" = {
    source = ./res/vimrc;
  };
  home.file.".vim/bundle/Vundle.vim" = {
    source = pkgs.vimPlugins.Vundle-vim;
    recursive = true; # Necessary because we are linking a whole directory
  };

  # Setup bashrc
  programs.bash = {
    enable = true;

    # Sets HISTCONTROL=ignoreboth (ignores duplicates and lines starting with
    # space)
    historyControl = [ "ignoreboth" ];

    # Infinite history
    historySize = -1;
    historyFileSize = -1;

    initExtra = ''
      # Append to the history file, don't overwrite it
      shopt -s histappend

      # Vim mode
      set -o vi

      # Custom Functions
      extract () {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xvjf $1    ;;
            *.tar.gz)    tar xvzf $1    ;;
            *.tar.xz)    tar xvf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xvf $1     ;;
            *.tbz2)      tar xvjf $1    ;;
            *.tgz)       tar xvzf $1    ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "don't know how to extract '$1'..." ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      cdg () {
        local repo_root

        repo_root=$(jj root 2>/dev/null)
        if [ -n "$repo_root" ]; then
          cd "$repo_root"
          return 0 
        fi

        repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$repo_root" ]; then
          cd "$repo_root"
          return 0 
        fi

        echo "Not in a recognized repository"
        return 1
      }

      # Fancy prompt
      if [ -f ~/.config/fancy_prompt.sh ]; then
        source ~/.config/fancy_prompt.sh
      fi
    '';
  };


  # Vim mode everywhere with readline
  #programs.readline = {
  #  enable = true;
  #  extraConfig = "set editing-mode vi";
  #};

  # Enable home-manager CLI
  programs.home-manager.enable = true;
}
