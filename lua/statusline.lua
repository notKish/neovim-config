local M = {}

local function get_git_branch()
  local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
  if branch == "" then
    return ""
  end
  local status = vim.fn.system("git status --porcelain 2>/dev/null")
  local dirty = status ~= ""
  return dirty and (branch .. "± ") or (branch .. " ")
end

local function get_mode()
  local mode = vim.api.nvim_get_mode().mode
  local mode_map = {
    n = "NORMAL",
    no = "NORMAL",
    v = "VISUAL",
    V = "VISUAL",
    ["\x16"] = "V-BLOCK",
    s = "SELECT",
    S = "SELECT",
    ["\x13"] = "V-SELECT",
    i = "INSERT",
    ic = "INSERT",
    R = "REPLACE",
    Rv = "V-REPLACE",
    c = "COMMAND",
    cv = "EX",
    ce = "EX",
    r = "INSERT",
    rm = "INSERT",
    ["r?"] = "INSERT",
    ["!"] = "INSERT",
    t = "TERMINAL",
  }
  return mode_map[mode] or "UNKNOWN"
end

local function get_readonly()
  if vim.bo.readonly or not vim.bo.modifiable then
    return "[RO]"
  end
  return ""
end

local function get_search_count()
  if vim.v.hlsearch == 0 then
    return ""
  end
  local result = vim.fn.searchcount({ recompute = true })
  if result.total == 0 then
    return ""
  end
  return result.current .. "/" .. result.total .. " "
end

local function get_filetype()
  local ft = vim.bo.filetype
  if ft == "" then
    return "none"
  end
  return ft
end

function M.statusline()
  local git = get_git_branch()
  local mode = get_mode()
  local fname = vim.fn.expand("%f")
  local readonly = get_readonly()
  local ft = get_filetype()
  local lnum = vim.fn.line(".")
  local col = vim.fn.col(".")
  local pct = math.floor((lnum / vim.fn.line("$")) * 100)
  local enc = vim.bo.fileencoding == "" and "UTF-8" or vim.bo.fileencoding:upper()
  local search = get_search_count()

  local git_hl = "StatuslineGit"
  if git ~= "" and string.find(git, "±") then
    git_hl = "StatuslineGitDirty"
  end

  local left = string.format(
    "%%#%s#%s%%#StatuslineMode# %s %%f%%#StatuslineReadonly#%s %%#StatuslineInfo#%s | Ln %d, Col %d | %d%%%% ",
    git_hl, git, mode, readonly, ft, lnum, col, pct
  )

  local right = string.format(
    "%%=%s%%#StatuslineSearch#%s%%#StatuslineSubtle# %s ",
    "%=", search, enc
  )

  return left .. right
end

vim.o.statusline = "%!v:lua.require('statusline').statusline()"

return M
