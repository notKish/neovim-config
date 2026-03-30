-- Native AI completion using MiniMax API (no plugins required).
-- <C-a>      — trigger: fires 3 parallel requests, shows first result as virtual text
-- <C-Enter>  — accept full current suggestion
-- <S-Enter>  — accept one line of current suggestion
-- <C-j>      — cycle to next suggestion
-- <C-k>      — cycle to previous suggestion
-- <C-e>      — dismiss

local M = {}
local api_key = vim.env.MINIMAX_API_KEY
local model = "MiniMax-M2.7"
local endpoint = "https://api.minimax.io/anthropic/v1/messages"
local NUM_SUGGESTIONS = 3
local ns = vim.api.nvim_create_namespace("ai_completion")

-- state
local state = {
  active = false,
  suggestions = {},
  index = 1,
  buf = nil,
  row = nil,
  col = nil,
  accepting_line = false, -- suppress auto-dismiss during line accept
  session = 0,            -- incremented on each trigger; callbacks check this before mutating
  accepting = false,      -- true once user starts accepting (locks suggestions list)
}

local function get_context()
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local before = table.concat(vim.list_slice(lines, 1, row - 1), "\n")
  local current_before = string.sub(lines[row] or "", 1, col)
  local current_after = string.sub(lines[row] or "", col + 1)
  local after = table.concat(vim.list_slice(lines, row + 1), "\n")
  return before .. "\n" .. current_before, current_after .. "\n" .. after
end

local function get_file_context()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  -- make it relative to cwd if possible
  local cwd = vim.fn.getcwd()
  if filepath:sub(1, #cwd) == cwd then
    filepath = filepath:sub(#cwd + 2)
  end

  -- collect import lines from the top of the file (up to first non-import line)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local imports = {}
  for _, line in ipairs(lines) do
    if line:match("^%s*import ") or line:match("^%s*from ") or line:match("^%s*require(") or line == "" then
      if line ~= "" then table.insert(imports, line) end
    else
      break
    end
  end

  return filepath, imports
end

local function build_prompt(prefix, suffix)
  local ft = vim.bo.filetype
  local filepath, imports = get_file_context()

  -- extract the last non-empty comment line from prefix as an optional instruction
  local instruction = ""
  for _, line in ipairs(vim.split(prefix, "\n", { plain = true })) do
    local comment = line:match("^%s*//+%s*(.+)$")
        or line:match("^%s*#%s*(.+)$")
        or line:match("^%s*%-%-%s*(.+)$")
    if comment then
      instruction = comment
    end
  end

  local directive = instruction ~= "" and ("Instruction from comment: " .. instruction .. "\n") or ""
  local file_info = "File: " .. filepath .. "\n"
  local import_info = #imports > 0
      and ("Existing imports:\n" .. table.concat(imports, "\n") .. "\n")
      or ""

  return string.format(
    "You are a code completion engine. Complete the code below.\n"
    .. "Language: %s\n"
    .. "%s"
    .. "%s"
    .. "%s"
    .. "Only output the completion text that comes AFTER the cursor position marked by <cursor/>.\n"
    .. "Do NOT repeat any text that appears before <cursor/>.\n"
    .. "No explanation, no markdown.\n\n"
    .. "<prefix>\n%s<cursor/>\n</prefix>\n\n"
    .. "<suffix>\n%s\n</suffix>",
    ft, file_info, import_info, directive, prefix, suffix
  )
end

local function strip(text)
  return text:gsub("^```%w*\n?", ""):gsub("\n?```$", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function show_virtual_text(text)
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local preview = vim.split(strip(text), "\n", { plain = true })
  -- first line inline after cursor
  local inline = { { " " .. preview[1], "Comment" } }
  -- remaining lines as virtual lines below
  local virt_lines = {}
  for i = 2, #preview do
    table.insert(virt_lines, { { preview[i], "Comment" } })
  end
  vim.api.nvim_buf_set_extmark(buf, ns, state.row - 1, -1, {
    virt_text = inline,
    virt_text_pos = "eol",
    virt_lines = #virt_lines > 0 and virt_lines or nil,
  })
end

local function clear_virtual_text()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  end
end

local function apply_action(action, client, buf)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
  end
  if action.command then
    local cmd = type(action.command) == "table" and action.command or action
    client:exec_cmd(cmd, { bufnr = buf })
  end
end

local function auto_import()
  local buf = vim.api.nvim_get_current_buf()

  local function request_imports()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      range = {
        start = { line = 0, character = 0 },
        ["end"] = { line = vim.api.nvim_buf_line_count(buf), character = 0 },
      },
      context = {
        diagnostics = {},
        only = { "source.addMissingImports", "source.fixAll" },
        triggerKind = 1,
      },
    }

    vim.lsp.buf_request(buf, "textDocument/codeAction", params, function(err, actions, ctx)
      if err then
        vim.notify("auto_import error: " .. vim.inspect(err), vim.log.levels.WARN)
        return
      end
      if not actions or #actions == 0 then
        vim.notify("auto_import: no actions returned", vim.log.levels.WARN)
        return
      end
      vim.notify(
      "auto_import: " .. #actions .. " action(s): " .. vim.inspect(vim.tbl_map(function(a) return a.title end, actions)),
        vim.log.levels.INFO)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if not client then return end
      for _, action in ipairs(actions) do
        if not action.edit and action.data and client:supports_method("codeAction/resolve") then
          client:request("codeAction/resolve", action, function(rerr, resolved)
            if not rerr and resolved then
              apply_action(resolved, client, buf)
            end
          end, buf)
        else
          apply_action(action, client, buf)
        end
      end
    end)
  end

  -- ts_ls needs ~500ms to process newly inserted text and produce diagnostics
  vim.defer_fn(request_imports, 500)
end

local function dismiss()
  clear_virtual_text()
  state.active = false
  state.accepting = false
  state.suggestions = {}
  state.index = 1
  state.session = state.session + 1 -- invalidate any in-flight callbacks
end

local function show_current()
  if #state.suggestions == 0 then return end
  show_virtual_text(state.suggestions[state.index])
end

local function accept_full()
  if not state.active or #state.suggestions == 0 then return end
  state.accepting = true
  local text = strip(state.suggestions[state.index])
  clear_virtual_text()
  state.active = false

  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_text(state.buf, state.row - 1, state.col, state.row - 1, state.col, lines)
  local new_row = state.row - 1 + #lines - 1
  local new_col = #lines > 1 and #lines[#lines] or state.col + #lines[1]
  vim.api.nvim_win_set_cursor(0, { new_row + 1, new_col })
  state.suggestions = {}
  vim.schedule(auto_import)
end

local function accept_line()
  if not state.active or #state.suggestions == 0 then return end
  local text = strip(state.suggestions[state.index])
  local lines = vim.split(text, "\n", { plain = true })
  local line = lines[1]

  state.accepting = true
  state.accepting_line = true

  -- figure out indentation of the next suggestion line (or current line if last)
  local next_line = lines[2] or line
  local indent = next_line:match("^(%s*)") or ""

  -- insert the line + newline with indentation
  vim.api.nvim_buf_set_text(state.buf, state.row - 1, state.col, state.row - 1, state.col, { line, indent })
  -- cursor moves to end of indentation on the new line
  state.row = state.row + 1
  state.col = #indent
  vim.api.nvim_win_set_cursor(0, { state.row, state.col })

  -- remove the accepted line from the suggestion
  table.remove(lines, 1)
  if #lines == 0 then
    state.accepting_line = false
    dismiss()
    vim.schedule(auto_import)
  else
    state.suggestions[state.index] = table.concat(lines, "\n")
    show_current()
    vim.schedule(function()
      state.accepting_line = false
    end)
  end
end

local function cycle(dir)
  if not state.active or #state.suggestions < 2 then return end
  state.index = ((state.index - 1 + dir) % #state.suggestions) + 1
  show_current()
  vim.notify(
    "Suggestion " .. state.index .. "/" .. #state.suggestions,
    vim.log.levels.INFO
  )
end

local function fetch_suggestion(prompt, temperature, on_result)
  local body = vim.json.encode({
    model = model,
    max_tokens = 512,
    temperature = temperature,
    system =
    "You are a code completion engine. Only output the completion text itself, no explanation, no markdown fences.",
    messages = {
      { role = "user", content = { { type = "text", text = prompt } } },
    },
  })

  vim.system(
    {
      "curl", "-s", "-X", "POST", endpoint,
      "-H", "Content-Type: application/json",
      "-H", "x-api-key: " .. api_key,
      "-H", "anthropic-version: 2023-06-01",
      "-d", body,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        on_result(nil)
        return
      end
      local ok, response = pcall(vim.json.decode, result.stdout)
      if not ok or type(response) ~= "table" or response.error then
        on_result(nil)
        return
      end
      for _, block in ipairs(response.content or {}) do
        if block.type == "text" and block.text ~= "" then
          on_result(block.text)
          return
        end
      end
      on_result(nil)
    end)
  )
end

function M.complete()
  if not api_key or api_key == "" then
    vim.notify("MINIMAX_API_KEY is not set", vim.log.levels.ERROR)
    return
  end

  dismiss()

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  state.buf = vim.api.nvim_get_current_buf()
  state.row = row
  state.col = col
  state.active = true
  state.session = state.session + 1
  local session = state.session

  local prefix, suffix = get_context()
  local prompt = build_prompt(prefix, suffix)
  local temperatures = { 0.2, 0.5, 0.8 }
  local done = 0

  vim.notify("AI completing…", vim.log.levels.INFO)

  for i = 1, NUM_SUGGESTIONS do
    fetch_suggestion(prompt, temperatures[i], function(text)
      -- discard if a new trigger fired or user already started accepting
      if state.session ~= session or state.accepting then return end
      done = done + 1
      if text then
        table.insert(state.suggestions, text)
        -- show virtual text as soon as first result arrives
        if #state.suggestions == 1 then
          show_current()
        end
      end
      if done == NUM_SUGGESTIONS then
        if #state.suggestions == 0 then
          vim.notify("AI returned no completions", vim.log.levels.WARN)
          state.active = false
        else
          vim.notify(
            #state.suggestions .. " suggestion(s) ready — <C-CR> accept, <S-CR> line, <C-j>/<C-k> cycle, <C-e> dismiss",
            vim.log.levels.INFO
          )
        end
      end
    end)
  end
end

-- keymaps (insert mode only, active when suggestion is showing)
vim.keymap.set("i", "<C-a>", function() M.complete() end, { desc = "AI complete (MiniMax)" })

vim.keymap.set("i", "<C-CR>", function()
  if state.active then accept_full() end
end, { desc = "AI accept full suggestion" })

vim.keymap.set("i", "<S-CR>", function()
  if state.active then accept_line() end
end, { desc = "AI accept one line" })

vim.keymap.set("i", "<C-j>", function()
  if state.active then cycle(1) end
end, { desc = "AI next suggestion" })

vim.keymap.set("i", "<C-k>", function()
  if state.active then cycle(-1) end
end, { desc = "AI prev suggestion" })

vim.keymap.set("i", "<C-e>", function()
  if state.active then
    dismiss()
  else
    -- fall back to default <C-e> (close completion menu)
    return vim.fn.pumvisible() == 1 and "<C-e>" or "<C-e>"
  end
end, { desc = "AI dismiss suggestion" })

-- auto-dismiss if cursor moves or mode changes (but not during line accept)
vim.api.nvim_create_autocmd("CursorMovedI", {
  callback = function()
    if state.active and not state.accepting_line then dismiss() end
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if state.active then dismiss() end
  end,
})

return M
