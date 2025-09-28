# neovim.nix
# A custom NeoVim configuration for NixOS using nixvim.
# https://github.com/nix-community/nixvim

{ ... }:

{
  imports = [
    ./coding.nix
  ];
  programs.nixvim = {
    enable = true;
    colorscheme = "unokai";

    # Make nvim the default editor and open even on `vi` and `vim`.
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # -------------------------------------------------------------------------
    # General Editor Settings
    # -------------------------------------------------------------------------
    opts = {
      # --- Line Numbers ---
      number = true;          # Show line numbers.
      relativenumber = false; # Use absolute line numbers.

      # --- Tabs and Indentation ---
      tabstop = 2;            # Number of spaces a <Tab> in the file counts for.
      shiftwidth = 2;         # Number of spaces to use for (auto)indent.
      expandtab = true;       # Use spaces instead of tabs.
      smartindent = true;     # Makes indenting smarter.

      # --- Visual Aids ---
      colorcolumn = "81";     # Show a colored column at 81 characters.
      cursorline = true;      # Highlight the current line.
      
      # --- Wrapping ---
      # This is a global setting. We'll refine it for specific filetypes.
      textwidth = 80;
      # Options:
      #  * `c` = auto-wrap comments
      #  * `r` = continue comment on enter
      #  * `o` = continue comment on o/O
      formatoptions = "jcroql";

      # Disable mouse support.
      mouse = "";
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    # -------------------------------------------------------------------------
    # Color Schemes
    # -------------------------------------------------------------------------
    # This only enables potential color scheme plugins.
    # -------------------------------------------------------------------------
    colorschemes.base16 = {
      # There are a lot of schemes in base16 repo - they should all now be
      # available, but not chosen.
      enable = true;
    };

    # -------------------------------------------------------------------------
    # Plugins
    # -------------------------------------------------------------------------
    plugins = {
      # --- Multi-Cursor Support ---
      # Enables multi-cursor editing.
      visual-multi = {
        enable = true;
        settings = {
          leader = ",";
          # Docs: https://github.com/mg979/vim-visual-multi/wiki/Mappings
          mappings = {
            "Find Under" = "<C-d>";
            "Find Subword Under" = "<C-d>";
            "Undo" = "u";
            "Redo" = "<C-r>";
          };
        };
      };

      # --- Surround Functionality ---
      # A modern replacement for vim-surround, written in Lua.
      # Examples:
      #  * ysiw" (surround word in quotes)
      #  * cs"' (change single to double quotes)
      nvim-surround = {
        enable = true;
      };
    };

    # -------------------------------------------------------------------------
    # Filetype-Specific Settings
    # -------------------------------------------------------------------------
    autoCmd = [
      {
        # Event triggers when a file of a certain type is loaded.
        event = "FileType";
        # The file types we want this to apply to.
        pattern = [ "markdown" "text" "gitcommit" ];
        # The command to run. `setlocal` makes it buffer-specific.
        command = "setlocal wrap";
      }
    ];
  };
}
