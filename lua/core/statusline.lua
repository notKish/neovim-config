-- Lightweight hand-rolled statusline

local function git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null | tr -d '\n'")
  if not handle then return "" end
  local branch = handle:read("*a")
  handle:close()
  return branch ~= "" and "  " .. branch .. " " or ""
end

local function file_type()
  local ft = vim.bo.filetype
  if ft == "" then return "  " end
  local icons = {
    lua = "LUA", python = "PY", javascript = "JS", typescript = "TS",
    html = "HTML", css = "CSS", json = "JSON", markdown = "MD",
    vim = "VIM", sh = "SH", go = "GO", rust = "RS", java = "JAVA",
  }
  return "[" .. (icons[ft] or ft) .. "]"
end

local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  return #clients > 0 and "  LSP " or ""
end

local function mode_label()
  local modes = {
    n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE",
    ["\22"] = "V-BLOCK", c = "COMMAND", s = "SELECT",
    R = "REPLACE", r = "REPLACE", t = "TERMINAL",
  }
  return modes[vim.fn.mode()] or vim.fn.mode():upper()
end

_G.sl_mode = mode_label
_G.sl_branch = git_branch
_G.sl_ft = file_type
_G.sl_lsp = lsp_status

local active_sl = table.concat({
  "  %#StatusLineBold#%{v:lua.sl_mode()}%#StatusLine#",
  " │ %f %h%m%r",
  "%{v:lua.sl_branch()}",
  " │ %{v:lua.sl_ft()}",
  "%{v:lua.sl_lsp()}",
  "%=",
  "%l:%c  %P ",
})

local inactive_sl = "  %f %h%m%r │ %{v:lua.sl_ft()} | %= %l:%c  %P "

local augroup = vim.api.nvim_create_augroup("Statusline", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = augroup,
  callback = function() vim.opt_local.statusline = active_sl end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = augroup,
  callback = function() vim.opt_local.statusline = inactive_sl end,
})

vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })
vim.cmd([[hi TabLineFill guibg=NONE ctermfg=242 ctermbg=NONE]])
