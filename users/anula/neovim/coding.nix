#
# Configuration needed for comfortable coding experience.
#

{ pkgs, ... }:

{
  programs.nixvim = {

    extraPackages = with pkgs; [
      # Lua tools
      lua-language-server
      stylua
      luajitPackages.luacheck
      # Nix tools
      nil
      nixpkgs-fmt
      statix
    ];

    plugins = {
      # --- LSP (Language Server Protocol) Support ---
      # We enable the core LSP config plugin, but configure servers below.
      lsp = {
        enable = true;
        onAttach =
          "require('coding-utils').lsp_on_attach_keymaps(client, bufnr)";
      };

      # -------------------------------------------------------------------------
      # LSP Server Configuration
      # -------------------------------------------------------------------------
      lsp.servers = {
        lua_ls = {
          enable = true;
          # Tell Lua to recognize vim as a global variable.
          settings.Lua.diagnostics.globals = [ "vim" ];
        };
        nil_ls = {
          enable = true;
        };
      };

      # Formatting
      conform-nvim = {
        enable = true;
        settings = {
          formatters = {
            nixpkgs-fmt = {
              command = "nixpkgs-fmt";
              args = [ "$FILENAME" ];
              stdin = false; # nixpkgs-fmt requires a filename
            };
          };
          formatters_by_ft = {
            # Lua formatter
            lua = [ "stylua" ];
            # Nix formatter
            nix = [ "nixpkgs-fmt" ];
          };
        };
      };

      # Linting
      lint = {
        enable = true;
        lintersByFt = {
          # Lua linter
          lua = [ "luacheck" ];
          # Nix linter
          nix = [ "statix" ];
        };
      };

      # Completion
      cmp = {
        enable = true;
      };
    };

    extraFiles = {
      "lua/coding-utils.lua" = {
        source = ./coding.lua;
      };
    };

    userCommands = {
      Format = {
        # This passes the range in args.
        range = true;
        command.__raw = "require('coding-utils').format_code";
        desc = "Format the current buffer or a selected range";
      };
    };

    keymaps = [
      # Formatting with conform plugin.
      {
        mode = "n";
        key = "<C-f>";
        action = ":Format<CR>";
        options.desc = "Format file";
      }
      {
        mode = "v";
        key = "<C-k>";
        action = ":Format<CR>";
        options.desc = "Format selection";
      }
    ];
  };
}
