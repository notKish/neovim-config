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
    n = "N",
    no = "N",
    v = "V",
    V = "V",
    ["\x16"] = "VB",
    s = "S",
    S = "S",
    ["\x13"] = "VS",
    i = "I",
    ic = "I",
    R = "R",
    Rv = "RV",
    c = "C",
    cv = "EX",
    ce = "EX",
    r = "R",
    rm = "R",
    ["r?"] = "R",
    ["!"] = "!",
    t = "T",
  }
  return mode_map[mode] or "?"
end

---Pad with spaces on the right until display width is `width`.
local function pad_display(s, width)
  local w = vim.fn.strwidth(s)
  if w >= width then
    return s
  end
  return s .. string.rep(" ", width - w)
end

---Truncate path from the left; result has display width exactly `width` (stable in vertical splits).
local function dir_fixed_width(s, width)
  if vim.fn.strwidth(s) <= width then
    return pad_display(s, width)
  end
  local ell = "…"
  local room = width - vim.fn.strwidth(ell)
  if room < 1 then
    return vim.fn.strcharpart(ell, 0, width)
  end
  local n = vim.fn.strchars(s, true)
  local acc = ""
  for i = n - 1, 0, -1 do
    local ch = vim.fn.strcharpart(s, i, 1)
    local cand = ch .. acc
    if vim.fn.strwidth(cand) > room then
      break
    end
    acc = cand
  end
  return pad_display(ell .. acc, width)
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

-- Directory segment width in display cells (works in vertical splits).
local DIR_WIDTH = 40

function M.statusline()
  local git = get_git_branch()
  local mode = get_mode()
  local dir = dir_fixed_width(vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":~:."), DIR_WIDTH)
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
    "%%#%s#%s%%#StatuslineMode# %-2s %%#StatuslineSubtle# %s%%#StatuslineReadonly#%s %%#StatuslineInfo#%s | %d, %d | %d%%%% ",
    git_hl, git, mode, dir, readonly, ft, lnum, col, pct
  )

  local right = string.format(
    "%%=%s%%#StatuslineSearch#%s%%#StatuslineSubtle# %s ",
    "%=", search, enc
  )

  return left .. right
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.wo.statusline = "%#Normal#"
    vim.wo.number = false
    vim.wo.relativenumber = false
  end,
})

function M.bufferline()
  local buffers = {}
  local items = {}
  local counts = {}

  -- First pass: collect buffer display names and count duplicates by basename.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local full = vim.api.nvim_buf_get_name(buf)
      local base = vim.fn.fnamemodify(full, ":t")
      if base == "" then base = "[No Name]" end

      counts[base] = (counts[base] or 0) + 1
      table.insert(items, { buf = buf, full = full, base = base })
    end
  end

  -- Second pass: render tabs. If basename duplicates, show parent dir tail too.
  for _, item in ipairs(items) do
    local buf = item.buf
    local current = buf == vim.api.nvim_get_current_buf()
    local modified_hl = vim.bo[buf].modified and "%#TabLineMod# ●%#TabLineSel#" or "%#TabLineSel#"
    local modified_hl_normal = vim.bo[buf].modified and "%#TabLineMod# ●%#TabLine#" or ""

    local label = item.base
    if counts[item.base] and counts[item.base] > 1 and item.full ~= "" then
      local dir = vim.fn.fnamemodify(item.full, ":p:h:t")
      if dir ~= "" then
        label = dir .. "/" .. item.base
      end
    end

    if current then
      table.insert(buffers, "%#TabLineSel# " .. label .. modified_hl .. " %#TabLineFill#")
    else
      table.insert(buffers, "%#TabLine# " .. label .. modified_hl_normal .. " ")
    end
  end

  return table.concat(buffers) .. "%#TabLineFill#"
end

vim.o.tabline = "%!v:lua.require('statusline').bufferline()"
vim.o.showtabline = 2

vim.o.statusline = "%!v:lua.require('statusline').statusline()"

return M
