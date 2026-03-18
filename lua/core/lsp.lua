-- LSP configuration using vim.lsp.enable() (Neovim 0.11+)
-- Server configs live in ~/.config/nvim/lsp/<servername>.lua

vim.lsp.enable({
  "lua_ls",
  "bashls",
  "pyright",
  "ruff",
  "ts_ls",
  "gopls",
  "clangd",
  "jdtls",
  "nil_ls",
})

-- Diagnostics display
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✗",
      [vim.diagnostic.severity.WARN] = "⚠",
      [vim.diagnostic.severity.INFO] = "ℹ",
      [vim.diagnostic.severity.HINT] = "󰌵",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded" },
})

-- Keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("gy", vim.lsp.buf.type_definition, "Type definition")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Format")
  end,
})
