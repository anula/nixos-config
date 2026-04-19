{ config, pkgs, inputs, ... }:

{
  imports = [
    ./neovim/default.nix
  ];

  home.username = "anula";
  home.homeDirectory = "/home/anula";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Terminal QoL programs
    tmux
    tree
    htop
    unzip
    unar
    p7zip
    bzip2
    gzip
    glow
    jq
    ffmpeg
    restic
    openssl
  ];

  # Persistent `nix develop` per directory 
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historySize = -1;
    historyFileSize = -1;

    initExtra = ''
      shopt -s histappend
      set -o vi

      extract () {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xvjf $1    ;;
            *.tar.gz)    tar xvzf $1    ;;
            *.tar.xz)    tar xvf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unar x $1      ;;
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

      if [ -f ~/.config/fancy_prompt.sh ]; then
        source ~/.config/fancy_prompt.sh
      fi
    '';
  };

  # Config files
  home.file.".config/tmux/tmux.conf".source = ./res/tmux.conf;
  home.file.".config/fancy_prompt.sh".source = ./res/fancy_prompt.sh;
  home.file.".vimrc".source = ./res/vimrc;
  home.file.".vim/bundle/Vundle.vim" = {
    source = pkgs.vimPlugins.Vundle-vim;
    recursive = true;
  };

  programs.home-manager.enable = true;
}
