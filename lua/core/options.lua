vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.g.mapleader = " "
vim.opt.clipboard = 'unnamedplus'

-- indentation
vim.opt.smartindent = true                         -- Smart auto-indenting
vim.opt.autoindent = true                          -- Copy indent from current line

-- file handling
vim.opt.autowrite = true													-- auto save

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
		source = 'if_many',
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