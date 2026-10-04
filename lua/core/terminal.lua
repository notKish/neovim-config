local map = vim.keymap.set
local terminal_buf = nil

local function toggle_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == terminal_buf then
      vim.api.nvim_win_close(win, false)
      return
    end
  end

  vim.cmd("botright 15split")
  local win = vim.api.nvim_get_current_win()

  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    terminal_buf = vim.api.nvim_create_buf(false, true)
    -- Buffer-local Esc so other term buffers (e.g. lazygit) receive Escape for the TUI.
    map("t", "<Esc>", "<C-\\><C-n>", { buffer = terminal_buf, desc = "Exit terminal mode" })
    vim.api.nvim_win_set_buf(win, terminal_buf)
    vim.fn.jobstart(vim.o.shell, {
      term = true,
      buf = terminal_buf,
      on_exit = function()
        terminal_buf = nil
      end,
    })
  else
    vim.api.nvim_win_set_buf(win, terminal_buf)
  end

  vim.cmd("startinsert")
end

map("n", "<A-/>", toggle_terminal, { desc = "Toggle terminal" })
map("t", "<A-/>", toggle_terminal, { desc = "Toggle terminal" })
map("t", "<A-Left>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
map("t", "<A-Down>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
map("t", "<A-Up>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
map("t", "<A-Right>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })
