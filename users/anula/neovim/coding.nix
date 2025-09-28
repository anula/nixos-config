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

    autoCmd = [
      {
        # Show diagnostics in command line on hover.
        event = "CursorHold";
        pattern = "*";
        callback = ''
          function()
            local severity_map = {
              [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
              [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
              [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
              [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
            }
            local diagnostics = vim.diagnostic.get_pos()
            if #diagnostics == 0 then
              vim.api.nvim_echo({{"", 'None'}}, false, {})
              return
            end
            local diagnostic = diagnostics[1]
            local message = diagnostic.message:gsub("\n", " ")
            local highlight = severity_map[diagnostic.severity] or "DiagnosticSignInfo"
            vim.api.nvim_echo({{message, highlight}}, false, {})
          end
        '';
      }
    ];
  };
}
