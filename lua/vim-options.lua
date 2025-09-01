vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.g.mapleader = " "
vim.opt.clipboard = 'unnamedplus'

vim.keymap.set("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selected lines down" })
vim.keymap.set("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selected lines up" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { desc = "Clear search highlight on Esc" })

-- windows
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })

vim.keymap.set("n", "<leader>q", "<C-w>q", { desc = "Close current pane" })
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Horizontal split" })

-- Window resizing
vim.keymap.set("n", "<leader>wh", "<cmd>resize +5<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<leader>wj", "<cmd>resize -5<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<leader>wl", "<cmd>vertical resize +5<CR>", { desc = "Increase window width" })
vim.keymap.set("n", "<leader>wk", "<cmd>vertical resize -5<CR>", { desc = "Decrease window width" })


-- buffers
vim.keymap.set("n", "<leader>bd", function()
	local cur_win = vim.api.nvim_get_current_win()
	vim.cmd("bprevious")
	vim.cmd("bdelete #")
	vim.api.nvim_set_current_win(cur_win)
end, { desc = "Delete current buffer, keep window" })

vim.keymap.set("n", "<leader>ba", ":%bd | e#<CR>", { desc = "Close all other buffers" })

vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

vim.diagnostic.config({
	virtual_text = {
		prefix = "●", -- or "", ">>", "", etc.
		spacing = 2,
		severity = nil, -- show all
	},
	signs = true, -- shows signs in the gutter
	underline = true,
	update_in_insert = false,
	float = {
		border = "rounded",
		source = "always",
	},
})


vim.api.nvim_create_autocmd('TextYankPost', {
	group = vim.api.nvim_create_augroup('highlight_yank', {}),
	desc = 'Highlight selection on yank',
	pattern = '*',
	callback = function()
		vim.highlight.on_yank { higroup = 'IncSearch', timeout = 500 }
	end,
})


vim.keymap.set('n', '<leader>ob', function()
  vim.fn.jobstart({ 'open', vim.fn.expand('%:p') }, { detach = true })
end, { noremap = true, silent = true })

