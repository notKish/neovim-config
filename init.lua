vim.g.mapleader = " "

-- Built-in plugin manager (Neovim 0.12+): :h vim.pack
require("pack-plugins")

-- Built-in retrobox; highlights.lua matches its palette for treesitter + statusline.
pcall(function()
  vim.cmd.colorscheme("retrobox")
end)

require("options")
require("completion")
local highlights = require("highlights")
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    highlights.apply()
  end,
})
require("keymaps")
require("lsp")
require("ai")
require("statusline")
require("terminal")
