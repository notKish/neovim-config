local map = vim.keymap.set

-- better up/down on wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- window resize
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize all windows" })
-- window splits
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Vertical split" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Horizontal split" })
-- window resize (M-* for true meta; CSI for xterm-style Alt+arrows; M-b/M-f for Ghostty on macOS — Option+Left/Right
-- are translated to ESC+b / ESC+f word-motion, not <M-Left>, when macos-option-as-alt is on)
local resize_maps = {
  { "<M-Up>", "<cmd>resize +2<cr>", "Increase window height" },
  { "<M-Down>", "<cmd>resize -2<cr>", "Decrease window height" },
  { "<M-Left>", "<cmd>vertical resize -2<cr>", "Decrease window width" },
  { "<M-Right>", "<cmd>vertical resize +2<cr>", "Increase window width" },
  { "<M-b>", "<cmd>vertical resize -2<cr>", "Decrease window width" },
  { "<M-f>", "<cmd>vertical resize +2<cr>", "Increase window width" },
  -- Alt+arrow: CSI 1 ; 3 (xterm) or ; 9 (some terminals) — Neovim often never sees <M-Left>
  { "\x1b[1;3A", "<cmd>resize +2<cr>", "Increase window height" },
  { "\x1b[1;3B", "<cmd>resize -2<cr>", "Decrease window height" },
  { "\x1b[1;3D", "<cmd>vertical resize -2<cr>", "Decrease window width" },
  { "\x1b[1;3C", "<cmd>vertical resize +2<cr>", "Increase window width" },
  { "\x1b[1;9A", "<cmd>resize +2<cr>", "Increase window height" },
  { "\x1b[1;9B", "<cmd>resize -2<cr>", "Decrease window height" },
  { "\x1b[1;9D", "<cmd>vertical resize -2<cr>", "Decrease window width" },
  { "\x1b[1;9C", "<cmd>vertical resize +2<cr>", "Increase window width" },
}
for _, row in ipairs(resize_maps) do
  map("n", row[1], row[2], { desc = row[3], silent = true })
end

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

---Pick another listed buffer for the current window, then delete `buf` (keeps splits).
local function delete_buffer_keep_windows(buf)
  local function pick_other()
    local alt = vim.fn.bufnr("#")
    if alt ~= -1 and alt ~= buf and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted and vim.api.nvim_buf_is_loaded(alt) then
      return alt
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= buf and vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) then
        return b
      end
    end
    return nil
  end

  local next_buf = pick_other()
  if next_buf then
    vim.api.nvim_set_current_buf(next_buf)
  else
    vim.cmd("enew")
  end

  local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
  if not ok then
    vim.api.nvim_set_current_buf(buf)
    if err then
      vim.notify(tostring(err), vim.log.levels.ERROR)
    end
  end
end

map("n", "<leader>bd", function()
  delete_buffer_keep_windows(vim.api.nvim_get_current_buf())
end, { desc = "Delete buffer (keep window layout)" })
map("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  local failed = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if not ok then
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" then name = ("[No Name " .. buf .. "]") end
        table.insert(failed, vim.fn.fnamemodify(name, ":~:."))
        if err then
          vim.schedule(function()
            vim.notify("Could not close buffer: " .. vim.fn.fnamemodify(name, ":~:."), vim.log.levels.WARN)
          end)
        end
      end
    end
  end
  if #failed > 0 then
    vim.notify("Some buffers were not closed (likely modified): " .. table.concat(failed, ", "), vim.log.levels.WARN)
  end
end, { desc = "Close all other buffers" })
map("n", "<leader>bl", "<cmd>ls<cr>", { desc = "List buffers" })
map("n", "<leader>bb", function() MiniPick.builtin.buffers() end, { desc = "Pick buffer" })

-- pickers: mini.pick (fuzzy finder UI)
map("n", "<leader><space>", function() MiniPick.builtin.files() end, { desc = "Find files" })
map("n", "<leader>?", function() MiniPick.builtin.grep_live() end, { desc = "Live grep" })
map("n", "<leader>fw", function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end, { desc = "Grep word under cursor" })
map("n", "<leader>fh", function() MiniPick.builtin.help() end, { desc = "Help tags" })
map("n", "<leader>fb", function() MiniPick.builtin.buffers() end, { desc = "Find buffers" })
map("n", "<leader>fg", function() MiniPick.builtin.git_files() end, { desc = "Find git files" })

-- move lines (visual only)
map("v", "<S-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<S-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- in normal mode, S-j appends the line below to the current line (default J behavior)
map("n", "<S-j>", "J", { desc = "Join line below" })

-- indenting keeps selection
map("v", "<", "<gv")
map("v", ">", ">gv")

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- save
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- quit
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- netrw file explorer
map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "File explorer" })
map("n", "-", "<cmd>Ex %:h<cr>", { desc = "Open netrw in current file's dir" })
-- map("n", "<leader>?", "<cmd>helptags ALL | help netrw-guide<cr>", { desc = "Netrw guide" })
map("n", "<leader>cg", "<cmd>Ex " .. vim.fn.stdpath("config") .. "<cr>", { desc = "Open nvim config dir" })

-- rename
map("n", "<leader>rn", function()
  local old = vim.api.nvim_buf_get_name(0)
  local new = vim.fn.input("Rename to: ", old, "file")
  if new == "" or new == old then return end
  local old_buf = vim.api.nvim_get_current_buf()
  vim.fn.rename(old, new)
  vim.cmd("edit " .. vim.fn.fnameescape(new))
  if vim.api.nvim_buf_is_valid(old_buf) and old_buf ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_buf_delete(old_buf, { force = false })
  end
end, { desc = "Rename current file" })

-- diagnostics
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "<leader>cd", function() vim.diagnostic.open_float() end, { desc = "Line diagnostics" })
map("n", "<leader>cl", function() vim.diagnostic.setqflist({ open = true }) end, { desc = "List all diagnostics (quickfix)" })

-- git
map("n", "<leader>gg", function()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.api.nvim_set_current_buf(buf)
  vim.fn.jobstart("lazygit", {
    term = true,
    on_exit = function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end,
  })
  vim.cmd("startinsert")
end, { desc = "Lazygit" })
