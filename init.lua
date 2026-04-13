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

-- Better startup screen when no files are opened
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 then
      local oldfiles = vim.v.oldfiles
      local lines = { "  Recent files:", "" }
      local count = 0
      for i = 1, #oldfiles do
        local file = oldfiles[i]
        if vim.fn.filereadable(file) == 1 then
          count = count + 1
          lines[#lines + 1] = "  " .. count .. ". " .. vim.fn.fnamemodify(file, ":~:.")
          if count >= 10 then break end
        end
      end
      if count == 0 then
        lines[#lines + 1] = "  (no recent files)"
      end
      lines[#lines + 1] = ""
      lines[#lines + 1] = "  Commands:"
      lines[#lines + 1] = "  <leader><space>  Find files"
      lines[#lines + 1] = "  <leader>?        Live grep"
      lines[#lines + 1] = "  <leader>e        File explorer"
      lines[#lines + 1] = "  <leader>gg       Lazygit"
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.bo.modifiable = false
      vim.bo.bufhidden = "wipe"
      vim.bo.swapfile = false
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"
    end
  end,
})
