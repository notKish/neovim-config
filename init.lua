vim.g.mapleader = " "

-- Explicitly set colorscheme, but never fail startup if unavailable.
local ok = pcall(vim.cmd.colorscheme, "catppuccin")
if not ok then
  pcall(vim.cmd.colorscheme, "habamax")
end

require("options")
require("highlights")
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    require("highlights")
  end,
})
require("keymaps")
require("completion")
require("lsp")
require("ai")
require("statusline")
require("terminal")
