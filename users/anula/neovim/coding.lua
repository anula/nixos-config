-- Methods table. Everything in it is exported.
local M = {}

-- Define LSP-specific keybindings in a function that we tell LSP to
-- always call on attaching.
function M.lsp_on_attach_keymaps(_, bufnr)

  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end
    vim.keymap.set(
      'n', keys, func,
      { buffer = bufnr, noremap = true, silent = true, desc = desc })
    end

    -- Core LSP Features
    nmap('K', vim.lsp.buf.hover, 'Hover documentation')
    nmap('gd', vim.lsp.buf.definition, 'Go to definition')
    nmap('gD', vim.lsp.buf.declaration, 'Go to declaration')
    nmap('gi', vim.lsp.buf.implementation, 'Go to implementation')
    nmap('gr', vim.lsp.buf.references, 'Go to references')
    nmap('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
    nmap('<leader>ca', vim.lsp.buf.code_action, 'Code action')

    -- Diagnostics
    nmap('gl', vim.diagnostic.open_float, 'Show line diagnostics')
    nmap('[d', vim.diagnostic.goto_prev, 'Go to previous diagnostic')
    nmap(']d', vim.diagnostic.goto_next, 'Go to next diagnostic')

  end

function M.format_code(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end
-- Create a custom Format command
-- vim.api.nvim_create_user_command("Format", function(args)
--   local range = nil
--   if args.count ~= -1 then
--     local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
--     range = {
--       start = { args.line1, 0 },
--       ["end"] = { args.line2, end_line:len() },
--     }
--   end
--   require("conform").format({ async = true, lsp_format = "fallback", range = range })
-- end, { range = true })

return M
