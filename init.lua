vim.g.mapleader = " "

-- External plugins via vim.pack: treesitter, friendly-snippets, mini.snippets (see lua/pack-plugins.lua). :h vim.pack :Pack
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
-- After LspAttach is registered: mini.snippets attaches here so vim.lsp.completion.enable runs (:h lsp-completion).
do
  local ok, err = pcall(require, "snippet_pack")
  if not ok then
    vim.notify("mini.snippets failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end
require("ai")
require("statusline")
require("terminal")
-- mini.pick for file finder UI (replaces vim.ui.select with fuzzy picker)
require("pick_pack")
