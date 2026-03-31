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
  install = { colorscheme = { "habamax" } },
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
require("lsp")
require("ai")
require("statusline")
require("terminal")
