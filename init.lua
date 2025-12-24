-- Set leader keys early (must be before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable providers you don't use (faster startup)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Disable Mason auto-install (Nix provides tooling)
vim.g.mason_disable = true

-- Load core config
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim and load plugins
require("config.lazy")

