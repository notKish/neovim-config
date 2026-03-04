-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ============================================================================
-- Dashboard / Starter (Find File, New File, Projects, etc.) — Snacks
-- ============================================================================
vim.keymap.set("n", "<leader>d.", function()
  if type(Snacks) == "table" and Snacks.dashboard then
    if Snacks.dashboard.open then
      Snacks.dashboard.open()
    else
      Snacks.dashboard()
    end
  end
end, { desc = "Open Dashboard (Starter)" })

-- ============================================================================
-- Visual Mode: Move Selected Lines Up/Down
-- ============================================================================
-- Move selected lines with Shift+J (down) and Shift+K (up)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })