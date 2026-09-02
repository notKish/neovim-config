vim.g.mapleader = " "

-- External plugins via vim.pack: treesitter, friendly-snippets, mini.snippets (see lua/plugins/init.lua). :h vim.pack :Pack
require("plugins")
require("plugins.treesitter")

-- Built-in retrobox; highlights.lua matches its palette for treesitter + statusline.
pcall(function()
  vim.cmd.colorscheme("retrobox")
end)

require("core.options")
require("core.completion")
local highlights = require("core.highlights")
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    highlights.apply()
  end,
})
require("core.keymaps")
require("core.lsp")
require("plugins.dap")
-- Arduino workflow: compile/upload/monitor via arduino-cli (:Arduino* commands)
require("plugins.arduino")
-- After LspAttach is registered: mini.snippets attaches here so vim.lsp.completion.enable runs (:h lsp-completion).
do
  local ok, err = pcall(require, "plugins.snippet")
  if not ok then
    vim.notify("mini.snippets failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end
require("plugins.ai")
require("plugins.codecompanion")
require("core.statusline")
require("core.terminal")
-- mini.pick for file finder UI (replaces vim.ui.select with fuzzy picker)
require("plugins.pick")
require("plugins.leetcode")
-- Startup screen (recent files + commands) when opening with no args
require("startup")
