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
      # Note: Rust tools (rust-analyzer, rustfmt) are NOT installed globally 
      # here to avoid version mismatches with project-specific toolchains.
      # They should be provided by a nix develop shell or similar.
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
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
          # Setting package to null so that no rust-analyzer is bundled with
          # neovim.
          # This way the rust-analyzer from PATH (eg. from nix develop) is used.
          package = null;
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
            rustfmt = {
              prepend_args = [ "--config" "max_width=80,tab_spaces=2" ];
            };
          };
          formatters_by_ft = {
            # Lua formatter
            lua = [ "stylua" ];
            # Nix formatter
            nix = [ "nixpkgs-fmt" ];
            # Python formatter
            python = [ "ruff_format" ];
            # Rust formatter
            rust = [ "rustfmt" ];
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
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
        };
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
