local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.cursorline = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true

-- Wrapping & scroll
opt.wrap = false
opt.scrolloff = 11
opt.sidescrolloff = 8

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Visual
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "120"
opt.showmode = false
opt.pumheight = 10
opt.conceallevel = 0
opt.splitbelow = true
opt.splitright = true

-- Files
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.updatetime = 250
opt.timeoutlen = 1000

-- Behaviour
opt.hidden = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.encoding = "UTF-8"
opt.iskeyword:append("-")
opt.path:append("**")

-- Folding (treesitter-aware, all open by default)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99

-- Completion
opt.completeopt = "menuone,noinsert,noselect"

-- Wildmenu
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Diff
opt.diffopt:append("linematch:60")

-- Performance
opt.redrawtime = 10000
opt.maxmempattern = 20000
opt.synmaxcol = 300

-- Cursor shape per mode
opt.guicursor = {
  "n-v-c:block",
  "i-ci-ve:ver25",
  "r-cr:hor20",
  "o:hor50",
  "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
  "sm:block-blinkwait175-blinkoff150-blinkon175",
}

-- Ensure undo dir exists
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
