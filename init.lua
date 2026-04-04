local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup("plugins", {
  defaults = { lazy = false },
  install = { colorscheme = { "retrobox" } },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        -- "netrwPlugin",
      },
    },
  },
})

-- Built-in retrobox; highlights.lua matches its palette for treesitter + statusline.
pcall(function()
  vim.cmd.colorscheme("retrobox")
end)

require("options")
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
