-- Set leader keys early (must be before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable providers you don't use (faster startup)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Disable Mason completely (Nix provides all tooling)
-- Set this VERY early, before any plugins load
vim.g.mason_disable = true
vim.env.MASON_DISABLE = "1"

-- Prevent Mason from loading at all
vim.g.loaded_mason = 1
vim.g.loaded_mason_lspconfig = 1

-- Disable LazyVim import order check (extras are imported in plugins/example.lua which is fine)
vim.g.lazyvim_check_order = false

-- Load core config
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim and load plugins
require("config.lazy")

