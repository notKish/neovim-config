vim.g.mapleader = " "
-- vim.g.maplocalleader = " "

-- completion navigation (not in netrw)
vim.keymap.set("i", "<Tab>", function()
  if vim.bo.filetype == "netrw" then return "<Tab>" end
  if vim.fn.pumvisible() == 1 then return "<Down>" end
  return "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  if vim.bo.filetype == "netrw" then return "<S-Tab>" end
  if vim.fn.pumvisible() == 1 then return "<Up>" end
  return "<S-Tab>"
end, { expr = true })
-- <CR> confirms selection, <C-y> also works
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })
vim.keymap.set("i", "<C-Space>", function()
  vim.lsp.completion.get()
end, { desc = "Trigger LSP completion" })

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
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })
-- hold <C-w> then keep pressing +/-/</>  to resize repeatedly
map("n", "<C-w>+", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-w>-", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-w><", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-w>>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
end, { desc = "Close all other buffers" })
map("n", "<leader>bl", "<cmd>ls<cr>", { desc = "List buffers" })
map("n", "<leader>bb", function()
  local bufs = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) ~= ""
  end, vim.api.nvim_list_bufs())
  local names = vim.tbl_map(function(b)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":~:.")
    local modified = vim.api.nvim_get_option_value("modified", { buf = b }) and " [+]" or ""
    return name .. modified
  end, bufs)
  vim.ui.select(names, { prompt = "Switch buffer:" }, function(_, idx)
    if idx then vim.api.nvim_set_current_buf(bufs[idx]) end
  end)
end, { desc = "Pick buffer" })

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
map("n", "<leader>?", "<cmd>helptags ALL | help netrw-guide<cr>", { desc = "Netrw guide" })
map("n", "<leader>rn", function()
  local old = vim.api.nvim_buf_get_name(0)
  local new = vim.fn.input("Rename to: ", old, "file")
  if new == "" or new == old then return end
  vim.fn.rename(old, new)
  vim.cmd("edit " .. vim.fn.fnameescape(new))
  vim.cmd("bdelete #")
end, { desc = "Rename current file" })

-- diagnostics
map("n", "[d", function() vim.diagnostic.goto_prev() end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.goto_next() end, { desc = "Next diagnostic" })
map("n", "<leader>cd", function() vim.diagnostic.open_float() end, { desc = "Line diagnostics" })
