# neovim.nix
# A custom NeoVim configuration for NixOS using nixvim.
# https://github.com/nix-community/nixvim

{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    colorscheme = "unokai";

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
    # Custom Key Mappings
    # -------------------------------------------------------------------------
    # TODO: These are untested so far.
    #keymaps = [
    #  # --- LSP Formatting ---
    #  {
    #    # Format the entire file with Ctrl+f in Normal mode.
    #    key = "<C-f>";
    #    mode = "n";
    #    action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>";
    #    options = {
    #      silent = true;
    #      desc = "LSP: Format buffer";
    #    };
    #  }
    #  {
    #    # Format the selected text with Ctrl+k in Visual mode.
    #    key = "<C-k>";
    #    mode = "v";
    #    action = "<cmd>lua vim.lsp.buf.format()<CR>";
    #    options = {
    #      silent = true;
    #      desc = "LSP: Format selection";
    #    };
    #  }
    #];


    # -------------------------------------------------------------------------
    # Color Schemes
    # -------------------------------------------------------------------------
    # This only enables potential color scheme plugins.
    # -------------------------------------------------------------------------
    colorschemes.base16 = {
      # base16 is a "template" on which many colorschemes are based.
      enable = true;
      colorscheme = "solarized-dark";
    };

    # -------------------------------------------------------------------------
    # Plugins
    # -------------------------------------------------------------------------
    plugins = {
      # --- LSP (Language Server Protocol) Support ---
      # We enable the core LSP config plugin, but configure servers below.
      lsp = {
        enable = true;
        
        # Global keymappings for LSP features
        keymaps = {
          #diagnostic.open_float = "gl";
          #definition.goto = "gd";
          #references.find = "gr";
          #hover.hover = "K";
          #implementation.goto = "gi";
          #rename.rename = "<leader>rn";
        };
      };

      # --- Multi-Cursor Support ---
      # Enables multi-cursor editing.
      visual-multi = {
        enable = true;
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
    # LSP Server Configuration
    # -------------------------------------------------------------------------
    lsp.servers = {
      # --- Python ---
      pylsp.enable = true;

      # --- Rust ---
      rust-analyzer = {
        enable = true;
        settings.check = {
          command = "clippy";
        };
      };

      # --- C/C++ ---
      clangd.enable = true;
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
