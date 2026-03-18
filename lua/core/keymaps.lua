vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = function(modes, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true }, opts or {})
  vim.keymap.set(modes, lhs, rhs, opts)
end

-- Clear search highlights
map("n", "<leader>c", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Centered jumps
map("n", "n", "nzzzv", { desc = "Next result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Splits
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertical" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split horizontal" })
map("n", "<C-Up>", ":resize +2<CR>", { desc = "Resize up" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Resize down" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize left" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize right" })

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bd", function()
  if #vim.fn.tabpagebuflist() > 1 then
    vim.cmd("bdelete")
  else
    vim.cmd("tabclose")
  end
end, { desc = "Smart close buffer" })

-- Move lines in visual mode
map("v", "<S-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<S-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep selection when indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Better J (keep cursor position)
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- File explorer
map("n", "<leader>e", ":Explore<CR>", { desc = "File explorer" })

-- Copy full path
map("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy file path" })

-- Edit config
map("n", "<leader>rc", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

-- Tabs
map("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", ":tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>t>", ":tabmove +1<CR>", { desc = "Move tab right" })
map("n", "<leader>t<", ":tabmove -1<CR>", { desc = "Move tab left" })

-- Format
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format file" })

-- Diagnostic navigation
map("n", "<leader>nd", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>pd", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "<leader>df", vim.diagnostic.open_float, { desc = "Diagnostic float" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostic list" })
