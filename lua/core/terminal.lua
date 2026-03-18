-- Floating terminal toggle
local state = { buf = nil, win = nil }

local function toggle()
  -- Close if open
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
    return
  end

  -- Create buffer once
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"
  end

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.wo[state.win].winblend = 0
  vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })
  vim.wo[state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"

  -- Start shell only on first open
  if vim.bo[state.buf].buftype ~= "terminal" then
    vim.fn.termopen(os.getenv("SHELL") or "sh")
  end

  vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>t", toggle, { desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
  end
end, { desc = "Close terminal" })
