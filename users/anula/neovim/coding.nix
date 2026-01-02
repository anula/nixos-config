#
# Configuration needed for comfortable coding experience.
#

{ pkgs, ... }:

let
  # Define a custom Ruff configuration file (Python, formatter)
  ruffConfig = pkgs.writeText "ruff.toml" ''
    line-length = 80
    indent-width = 2
    
    [format]
    indent-style = "space"
  '';
in
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
      # Python tools
      pyright
      ruff
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
          settings = {
            format = {
              enable = true;
              defaultConfig = {
                indent_style = "space";
                indent_size = "2";
              };
            };
            diagnostics = {
              globals = [ "vim" ];
            };
          };
        };
        nil_ls = {
          enable = true;
        };
        pyright = {
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
            stylua = {
              command = "stylua";
              prepend_args = [
                "--column-width" "80"
                "--indent-type" "Spaces"
                "--indent-width" "2"
              ];
            };
            ruff_format = {
              prepend_args = [ "--config" "${ruffConfig}" ];
            };
          };
          formatters_by_ft = {
            # Lua formatter
            lua = [ "stylua" ];
            # Nix formatter
            nix = [ "nixpkgs-fmt" ];
            # Python formatter
            python = [ "ruff_format" ];
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
          # Python linter
          python = [ "ruff" ];
        };
        linters = {
          luacheck = {
            args = [
              "--globals=vim"
            ];
          };
          ruff = {
            args = [
              "check"
              "--config" "${ruffConfig}"
            ];
          };
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
        action = ":%Format<CR>";
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
