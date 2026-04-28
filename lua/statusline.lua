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
    "%%=%%#StatuslineSearch#%s%%#StatuslineSubtle# %s ",
    search, enc
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

---Approximate display width of one tab cell (highlight codes do not occupy columns).
local function tab_cell_width(label, modified)
  local dot = modified and " ●" or ""
  return vim.fn.strwidth(" " .. label .. dot .. " ")
end

---Shrink label so tab fits in `max_w` display cells (for extreme narrow terminals).
local function truncate_label(label, max_w)
  if vim.fn.strwidth(label) <= max_w then
    return label
  end
  local ell = "…"
  if max_w <= vim.fn.strwidth(ell) then
    return vim.fn.strcharpart(ell, 0, max_w)
  end
  local room = max_w - vim.fn.strwidth(ell)
  local acc = ""
  for i = 0, vim.fn.strchars(label, true) - 1 do
    local ch = vim.fn.strcharpart(label, i, 1)
    local cand = acc .. ch
    if vim.fn.strwidth(cand) > room then
      break
    end
    acc = cand
  end
  return ell .. acc
end

---Pick [lo, hi] indices so current buffer stays visible and tabs fit in `avail` columns.
local function visible_tab_range(widths, cur_idx, avail)
  local n = #widths
  if n == 0 then
    return 1, 0
  end
  cur_idx = math.min(math.max(cur_idx, 1), n)
  avail = math.max(avail, 8)

  local total = 0
  for _, w in ipairs(widths) do
    total = total + w
  end
  total = total + math.max(0, n - 1)
  if total <= avail then
    return 1, n
  end

  local lo, hi = cur_idx, cur_idx
  local used = widths[cur_idx]

  -- Prefer growing to the right (later buffers), then fill left — keeps active tab in view.
  while hi < n do
    local next_w = widths[hi + 1]
    if used + 1 + next_w > avail then
      break
    end
    used = used + 1 + next_w
    hi = hi + 1
  end
  while lo > 1 do
    local prev_w = widths[lo - 1]
    if used + 1 + prev_w > avail then
      break
    end
    used = used + 1 + prev_w
    lo = lo - 1
  end

  -- Active tab wider than viewport: still show only that tab (truncation handles label).
  return lo, hi
end

function M.bufferline()
  local counts = {}
  local entries = {}

  -- First pass: collect buffers and count duplicates by basename.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local full = vim.api.nvim_buf_get_name(buf)
      local base = vim.fn.fnamemodify(full, ":t")
      if base == "" then
        base = "[No Name]"
      end

      counts[base] = (counts[base] or 0) + 1
      table.insert(entries, { buf = buf, full = full, base = base })
    end
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_idx = 1
  for i, e in ipairs(entries) do
    if e.buf == cur_buf then
      cur_idx = i
      break
    end
  end

  if #entries == 0 then
    return "%#TabLineFill#"
  end

  -- Final labels + widths
  local labels = {}
  local widths = {}
  local modified_flags = {}

  for _, item in ipairs(entries) do
    local label = item.base
    if counts[item.base] and counts[item.base] > 1 and item.full ~= "" then
      local dir = vim.fn.fnamemodify(item.full, ":p:h:t")
      if dir ~= "" then
        label = dir .. "/" .. item.base
      end
    end

    local mod = vim.bo[item.buf].modified
    labels[#labels + 1] = label
    modified_flags[#modified_flags + 1] = mod
    widths[#widths + 1] = tab_cell_width(label, mod)
  end

  local cols = vim.o.columns
  local scroll_ind_w = vim.fn.strwidth("< ")
  local avail = cols
  local lo, hi = visible_tab_range(widths, cur_idx, avail)
  local ind_left = lo > 1
  local ind_right = hi < #entries
  if ind_left or ind_right then
    avail = cols - (ind_left and scroll_ind_w or 0) - (ind_right and scroll_ind_w or 0)
    lo, hi = visible_tab_range(widths, cur_idx, avail)
    ind_left = lo > 1
    ind_right = hi < #entries
  end

  local buffers = {}
  if ind_left then
    table.insert(buffers, "%#TabLine# <%#TabLineFill# ")
  end

  for i = lo, hi do
    local buf = entries[i].buf
    local label = labels[i]
    local modified = modified_flags[i]
    local current = buf == cur_buf

    -- Shrink only when this slice still overflows (e.g. huge single title).
    local max_label_w = math.max(8, avail - 4)
    if hi == lo and tab_cell_width(label, modified) > avail then
      label = truncate_label(label, max_label_w)
    end

    local modified_hl = modified and "%#TabLineMod# ●%#TabLineSel#" or "%#TabLineSel#"
    local modified_hl_normal = modified and "%#TabLineMod# ●%#TabLine#" or ""

    if current then
      table.insert(buffers, "%#TabLineSel# " .. label .. modified_hl .. " %#TabLineFill#")
    else
      table.insert(buffers, "%#TabLine# " .. label .. modified_hl_normal .. " ")
    end
  end

  if ind_right then
    table.insert(buffers, "%#TabLine# >%#TabLineFill# ")
  end

  return table.concat(buffers) .. "%#TabLineFill#"
end

vim.o.tabline = "%!v:lua.require('statusline').bufferline()"
vim.o.showtabline = 2

vim.o.statusline = "%!v:lua.require('statusline').statusline()"

return M
