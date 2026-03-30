local opt = vim.opt

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 500 })
  end,
})

-- line numbers
opt.number         = true
opt.relativenumber = true

-- indentation
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

-- search
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

-- appearance
opt.termguicolors  = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.colorcolumn    = "120"

-- splits
opt.splitright     = true
opt.splitbelow     = true
opt.equalalways    = true -- auto-equalize windows when one is closed

-- misc
opt.swapfile       = false
opt.backup         = false
opt.undofile       = true
opt.undodir        = vim.fn.stdpath("data") .. "/undo"
opt.updatetime     = 250
opt.timeoutlen     = 300

opt.clipboard      = "unnamedplus"
opt.mouse          = "a"
opt.showmode       = false

-- better built-in fuzzy find / wildmenu (no plugin needed)
opt.path:append("**")
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o", "*.pyc", "node_modules/**", ".git/**" })

-- netrw settings
vim.g.netrw_banner          = 0
vim.g.netrw_liststyle       = 1
-- When selecting a file in netrw, open it in the same window.
-- Use manual splits (e.g., :vsplit) if you want netrw to stay open.
vim.g.netrw_localcopycmd    = "cp"
vim.g.netrw_localcopydircmd = "cp -r"
vim.g.netrw_localmovecmd    = "mv"
vim.g.netrw_sort_sequence   = "[\\/]$,*"
vim.g.netrw_sort_direction  = 'normal'

-- make marked files clearly visible + restore window nav keys netrw overrides
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.api.nvim_set_hl(0, "netrwMarkFile", { fg = "#f38ba8", bold = true, underline = true })
    local buf = vim.api.nvim_get_current_buf()
    -- netrw steals <C-l> for refresh — remap refresh to <leader>r and restore navigation
    vim.keymap.set("n", "<C-h>", function() vim.cmd("wincmd h") end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<C-j>", function() vim.cmd("wincmd j") end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<C-k>", function() vim.cmd("wincmd k") end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<C-l>", function() vim.cmd("wincmd l") end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<leader>r", "<Plug>NetrwRefresh", { buffer = buf })

    -- show current target and marked files (works from any netrw window)
    vim.keymap.set("n", "<leader>ms", function()
      local t = vim.g.netrw_localmovecmd_target or "(not set — use mt to set)"
      -- marked files are stored per-buffer in netrw_markfilelist
      local marked = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local ok, mfl = pcall(vim.api.nvim_buf_get_var, b, "netrw_markfilelist")
        if ok and type(mfl) == "table" then
          for _, f in ipairs(mfl) do
            table.insert(marked, f)
          end
        end
      end
      local lines = { "  Target : " .. tostring(t), "", "  Marked files:" }
      if #marked == 0 then
        table.insert(lines, "    (none — use mf to mark)")
      else
        for _, f in ipairs(marked) do
          table.insert(lines, "    " .. f)
        end
      end
      table.insert(lines, "")
      table.insert(lines, "  mc = copy  |  mm = move  |  mu = unmark all")
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end, { buffer = buf, desc = "Show netrw target and marked files" })
  end,
})
