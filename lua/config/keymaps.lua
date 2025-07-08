-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv'")
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv'")
