-- LSP completion configuration

local M = {}

function M.setup()
  -- Set completeopt for better popup behavior
  vim.opt.completeopt = {"menu", "menuone", "noinsert", "noselect"}

  -- Manually trigger completion with Ctrl+Space
  vim.keymap.set("i", "<C-Space>", function()
    vim.lsp.completion.get()
  end, { desc = "Trigger LSP completion" })
end

M.setup()

return M
