-- Fuzzy picker with live preview (no plugins, pure Neovim API).
--
-- <leader>ff  — find files
-- <leader>fg  — live grep
-- <leader>fw  — grep word under cursor
--
-- Inside the picker:
--   type            — filter / search
--   <C-j> / <Down>  — next result
--   <C-k> / <Up>    — prev result
--   <CR>            — open
--   <Tab>           — cycle focus: prompt → list → preview
--   <C-f> / <C-b>   — scroll preview
--   <Esc> / <C-c>   — close

local M = {}
local state = {}

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function win_valid(w) return w and vim.api.nvim_win_is_valid(w) end
local function buf_valid(b) return b and vim.api.nvim_buf_is_valid(b) end

local function buf_lock(buf)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function buf_set(buf, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function buf_hl(buf, hl, line)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  if line then vim.api.nvim_buf_add_highlight(buf, -1, hl, line, 0, -1) end
end

-- ─── destroy ─────────────────────────────────────────────────────────────────

local function destroy()
  if not next(state) then return end  -- already destroyed
  if state.aug then pcall(vim.api.nvim_del_augroup_by_id, state.aug) end
  if state.timer then state.timer:stop() end
  for _, w in ipairs { "prompt_win","list_win","preview_win" } do
    if win_valid(state[w]) then pcall(vim.api.nvim_win_close, state[w], true) end
  end
  for _, b in ipairs { "prompt_buf","list_buf","preview_buf" } do
    if buf_valid(state[b]) then pcall(vim.api.nvim_buf_delete, state[b], { force = true }) end
  end
  state = {}
end

-- ─── preview ─────────────────────────────────────────────────────────────────

local function update_preview(entry)
  if not buf_valid(state.preview_buf) then return end
  if not entry or entry == "" then buf_set(state.preview_buf, {}); return end

  local file, lnum = entry:match("^(.+):(%d+):%d+:")
  if not file then file = entry end
  lnum = tonumber(lnum) or 1

  if vim.fn.filereadable(file) == 0 then buf_set(state.preview_buf, {}); return end
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then buf_set(state.preview_buf, {}); return end

  buf_set(state.preview_buf, lines)
  pcall(vim.api.nvim_set_option_value, "filetype",
    vim.filetype.match({ filename = file }) or "", { buf = state.preview_buf })
  -- re-lock after filetype set (ft plugins may re-enable modifiable)
  buf_lock(state.preview_buf)

  if win_valid(state.preview_win) then
    local t = math.max(1, math.min(lnum, #lines))
    pcall(vim.api.nvim_win_set_cursor, state.preview_win, { t, 0 })
    vim.api.nvim_win_call(state.preview_win, function() vim.cmd("normal! zz") end)
    buf_hl(state.preview_buf, "CursorLine", t - 1)
  end
end

-- ─── render list ─────────────────────────────────────────────────────────────

local function render_list()
  if not buf_valid(state.list_buf) then return end
  local items  = state.filtered or {}
  local cursor = state.cursor   or 1
  local width  = win_valid(state.list_win)
    and vim.api.nvim_win_get_width(state.list_win) or 40

  local lines = {}
  for i, item in ipairs(items) do
    local prefix  = i == cursor and "▶ " or "  "
    local display = vim.fn.fnamemodify(item:gsub("\n",""), ":~:.")
    if #display > width - 3 then display = "…" .. display:sub(-(width - 4)) end
    table.insert(lines, prefix .. display)
  end

  buf_set(state.list_buf, lines)
  buf_hl(state.list_buf, "CursorLine", cursor <= #lines and cursor - 1 or nil)

  if win_valid(state.list_win) and cursor <= #lines then
    pcall(vim.api.nvim_win_set_cursor, state.list_win, { cursor, 0 })
    vim.api.nvim_win_call(state.list_win, function() vim.cmd("normal! zz") end)
  end

  if win_valid(state.list_win) then
    vim.api.nvim_win_set_config(state.list_win, {
      title = string.format(" %d results ", #items), title_pos = "left",
    })
  end

  update_preview(items[cursor])
end

-- ─── filter / grep ───────────────────────────────────────────────────────────

local function filter_files(q)
  if not state.all_items then return end
  local result = {}
  if q == "" then
    result = vim.list_slice(state.all_items, 1, 500)
  else
    local has_upper = q:match("%u")
    local pat = has_upper and q or q:lower()
    for _, item in ipairs(state.all_items) do
      local hay = has_upper and item or item:lower()
      if hay:find(pat, 1, true) then
        table.insert(result, item)
        if #result >= 500 then break end
      end
    end
  end
  state.filtered = result
  state.cursor   = 1
  render_list()
end

local function grep_live(q)
  if not state.timer then state.timer = vim.uv.new_timer() end
  state.timer:stop()
  if q == "" then
    state.filtered = {}; state.cursor = 1; render_list(); return
  end
  state.timer:start(150, 0, vim.schedule_wrap(function()
    if not state.list_buf then return end
    local out = vim.fn.systemlist(
      "rg --column --line-number --no-heading --smart-case " .. vim.fn.shellescape(q))
    state.filtered = vim.list_slice(out, 1, 500)
    state.cursor   = 1
    render_list()
  end))
end

-- ─── confirm ─────────────────────────────────────────────────────────────────

local function confirm()
  local entry = (state.filtered or {})[state.cursor or 1]
  destroy()
  if not entry then return end
  local file, line, col = entry:match("^(.+):(%d+):(%d+):")
  if file then
    vim.cmd("edit " .. vim.fn.fnameescape(file))
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), tonumber(col) - 1 })
  else
    vim.cmd("edit " .. vim.fn.fnameescape(entry))
  end
end

-- ─── focus cycle ─────────────────────────────────────────────────────────────

local function cycle_focus()
  local order = { state.prompt_win, state.list_win, state.preview_win }
  local cur   = vim.api.nvim_get_current_win()
  for i, w in ipairs(order) do
    if w == cur then
      local nxt = order[(i % #order) + 1]
      if win_valid(nxt) then
        vim.api.nvim_set_current_win(nxt)
        if nxt == state.prompt_win then vim.cmd("startinsert") end
      end
      return
    end
  end
end

-- ─── open picker ─────────────────────────────────────────────────────────────

local function open_picker(title, on_change)
  destroy()
  state.cursor   = 1
  state.filtered = {}
  state.query    = ""

  local ui   = vim.api.nvim_list_uis()[1]
  local tw   = math.floor(ui.width  * 0.90)
  local th   = math.floor(ui.height * 0.85)
  local lw   = math.floor(tw * 0.40)
  local rw   = tw - lw - 3
  local row  = math.floor((ui.height - th) / 2)
  local col  = math.floor((ui.width  - tw) / 2)
  local lh   = th - 4

  -- buffers
  state.prompt_buf  = vim.api.nvim_create_buf(false, true)
  state.list_buf    = vim.api.nvim_create_buf(false, true)
  state.preview_buf = vim.api.nvim_create_buf(false, true)

  for _, buf in ipairs({ state.list_buf, state.preview_buf }) do
    vim.api.nvim_set_option_value("buftype",   "nofile", { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe",   { buf = buf })
    vim.api.nvim_set_option_value("swapfile",  false,    { buf = buf })
    buf_lock(buf)
  end

  -- windows
  state.prompt_win = vim.api.nvim_open_win(state.prompt_buf, false, {
    relative="editor", row=row,     col=col,      width=lw, height=1,
    style="minimal",   border="rounded",
    title=" "..title.." ", title_pos="left",
  })
  state.list_win = vim.api.nvim_open_win(state.list_buf, false, {
    relative="editor", row=row+3,   col=col,      width=lw, height=lh,
    style="minimal",   border="rounded",
    title=" 0 results ", title_pos="left",
  })
  state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
    relative="editor", row=row,     col=col+lw+2, width=rw, height=th,
    style="minimal",   border="rounded",
    title=" preview ", title_pos="left",
  })

  for _, w in ipairs { state.list_win, state.preview_win } do
    vim.api.nvim_set_option_value("number",     true,  { win = w })
    vim.api.nvim_set_option_value("cursorline", true,  { win = w })
    vim.api.nvim_set_option_value("wrap",       false, { win = w })
  end

  -- focus prompt and enter insert
  vim.api.nvim_set_current_win(state.prompt_win)
  vim.cmd("startinsert")

  -- keymaps
  local bufs = { state.prompt_buf, state.list_buf, state.preview_buf }
  local function pmap(lhs, fn)
    for _, b in ipairs(bufs) do
      vim.keymap.set({"i","n"}, lhs, fn, { buffer=b, nowait=true, silent=true })
    end
  end

  local function move(d) return function()
    local n = #(state.filtered or {})
    if n == 0 then return end
    state.cursor = math.max(1, math.min((state.cursor or 1) + d, n))
    render_list()
  end end

  pmap("<CR>",    confirm)
  pmap("<Esc>",   destroy)
  pmap("<C-c>",   destroy)
  pmap("<C-j>",   move(1))
  pmap("<Down>",  move(1))
  pmap("<C-k>",   move(-1))
  pmap("<Up>",    move(-1))
  pmap("<Tab>",   cycle_focus)
  pmap("<C-f>",   function()
    if win_valid(state.preview_win) then
      vim.api.nvim_win_call(state.preview_win, function() vim.cmd("normal! \6") end)
    end
  end)
  pmap("<C-b>",   function()
    if win_valid(state.preview_win) then
      vim.api.nvim_win_call(state.preview_win, function() vim.cmd("normal! \2") end)
    end
  end)

  -- autocmds
  state.aug = vim.api.nvim_create_augroup("FuzzyPicker_"..tostring(math.random(1e6)), { clear=true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group  = state.aug,
    buffer = state.preview_buf,
    callback = function() buf_lock(state.preview_buf) end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group  = state.aug,
    buffer = state.list_buf,
    callback = function() buf_lock(state.list_buf) end,
  })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group  = state.aug,
    buffer = state.prompt_buf,
    callback = function()
      local q = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, 1, false)[1] or ""
      if q ~= state.query then
        state.query = q
        on_change(q)
      end
    end,
  })

  -- close if user somehow exits to a non-picker window (e.g. mouse click)
  vim.api.nvim_create_autocmd("WinEnter", {
    group = state.aug,
    callback = function()
      vim.schedule(function()
        if not state.prompt_win then return end
        local cur = vim.api.nvim_get_current_win()
        if cur ~= state.prompt_win
          and cur ~= state.list_win
          and cur ~= state.preview_win then
          destroy()
        end
      end)
    end,
  })
end

-- ─── public ──────────────────────────────────────────────────────────────────

function M.find_files()
  local all = vim.fn.systemlist("rg --files --hidden --glob '!.git'")
  if #all == 0 then vim.notify("No files found", vim.log.levels.WARN); return end
  open_picker("find files", filter_files)
  -- set items and render after picker is open
  state.all_items = all
  state.filtered  = vim.list_slice(all, 1, 500)
  state.cursor    = 1
  render_list()
end

function M.grep(seed)
  open_picker("live grep", grep_live)
  if seed and seed ~= "" then
    vim.schedule(function()
      if not buf_valid(state.prompt_buf) then return end
      vim.api.nvim_set_option_value("modifiable", true, { buf = state.prompt_buf })
      vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { seed })
      pcall(vim.api.nvim_win_set_cursor, state.prompt_win, { 1, #seed })
      grep_live(seed)
    end)
  end
end

function M.grep_word() M.grep(vim.fn.expand("<cword>")) end

vim.keymap.set("n", "<leader>ff", M.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", M.grep,        { desc = "Live grep" })
vim.keymap.set("n", "<leader>fw", M.grep_word,   { desc = "Grep word under cursor" })

return M
