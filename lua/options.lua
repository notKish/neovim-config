local opt = vim.opt

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 500 })
  end,
})

-- line numbers
opt.number = true
opt.relativenumber = true

-- indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.colorcolumn = "120"

-- splits
opt.splitright = true
opt.splitbelow = true

-- misc
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = { "menuone", "noselect", "noinsert", "popup" }
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.showmode = false

-- better built-in fuzzy find / wildmenu (no plugin needed)
opt.path:append("**")
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o", "*.pyc", "node_modules/**", ".git/**" })

-- netrw settings
vim.g.netrw_banner    = 0        -- hide the banner
vim.g.netrw_liststyle = 1        -- long listing by default
vim.g.netrw_browse_split = 0     -- open files in same window
vim.g.netrw_localcopycmd  = "cp -r"   -- recursive copy
vim.g.netrw_localmovecmd  = "mv"
