local M = {}

local REGISTRY = {
  lua = true,
  python = false,
  javascript = false,
  typescript = false,
  bash = false,
  markdown = true,
  json = false,
  toml = false,
  c = true,
  vim = true,
  vimdoc = true,
}

local BUILTIN_PARSERS = {
  lua = true,
  c = true,
  markdown = true,
  markdown_inline = true,
  query = true,
  vim = true,
  vimdoc = true,
}

local PARSER_DIR = vim.fn.stdpath("data") .. "/tree-sitter-parsers"
local NPM_DIR = vim.fn.stdpath("data") .. "/node_modules"
local OS = vim.loop.os_uname().sysname
local ARCH = vim.loop.os_uname().machine
local EXT = OS == "Darwin" and "dylib" or "so"

vim.opt.runtimepath:append(PARSER_DIR)

local function ensure_parser_dir()
  if vim.fn.isdirectory(PARSER_DIR) == 0 then
    vim.fn.mkdir(PARSER_DIR, "p")
  end
end

local function wasm_path(lang)
  return string.format("%s/%s.wasm", PARSER_DIR, lang)
end

local function is_parser_installed(lang)
  return vim.fn.filereadable(wasm_path(lang)) == 1
end

local function npm_grammar_path(lang)
  local npm_names = {
    python = "tree-sitter-python",
    javascript = "tree-sitter-javascript",
    typescript = "tree-sitter-typescript",
    bash = "tree-sitter-bash",
    json = "tree-sitter-json",
    toml = "tree-sitter-toml",
  }
  return NPM_DIR .. "/node_modules/" .. (npm_names[lang] or "")
end

local function get_cli_path()
  return NPM_DIR .. "/node_modules/.bin/tree-sitter"
end

local function install_via_npm(lang)
  local grammar_path = npm_grammar_path(lang)
  if vim.fn.isdirectory(grammar_path) ~= 1 then return false end
  local cli = get_cli_path()
  if vim.fn.filereadable(cli) ~= 1 then return false end
  local wasm_out = wasm_path(lang)
  local cmd = string.format(
    "cd %s && %s build --wasm --output %s 2>&1",
    vim.fn.shellescape(grammar_path),
    cli,
    wasm_out
  )
  vim.fn.system(cmd)
  return vim.fn.filereadable(wasm_out) == 1
end

local function install_parser(lang)
  if BUILTIN_PARSERS[lang] then return true end
  if is_parser_installed(lang) then return true end
  ensure_parser_dir()
  local ok = install_via_npm(lang)
  if ok then
    vim.notify("Installed tree-sitter parser: " .. lang, vim.log.levels.INFO)
  end
  return is_parser_installed(lang)
end

function M.install_parsers()
  ensure_parser_dir()
  local installed = {}
  local failed = {}
  for lang, _ in pairs(REGISTRY) do
    if BUILTIN_PARSERS[lang] then
      table.insert(installed, lang .. " (builtin)")
    elseif install_parser(lang) then
      table.insert(installed, lang)
    else
      table.insert(failed, lang)
    end
  end
  if #installed > 0 then
    vim.notify("Tree-sitter: " .. table.concat(installed, ", "), vim.log.levels.INFO)
  end
  if #failed > 0 then
    vim.notify(
      "Tree-sitter parsers need manual install: " .. table.concat(failed, ", "),
      vim.log.levels.WARN
    )
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(REGISTRY),
  callback = function(args)
    local lang = args.match
    if BUILTIN_PARSERS[lang] then
      pcall(vim.treesitter.start, args.buf, lang)
      vim.b[args.buf].ts_active = true
      return
    end
    if not is_parser_installed(lang) then
      install_parser(lang)
    end
    if is_parser_installed(lang) then
      pcall(vim.treesitter.start, args.buf, lang)
      vim.b[args.buf].ts_active = true
    end
  end,
})

local function get_tree_root(lang)
  lang = lang or vim.bo.filetype
  local parser = vim.treesitter.get_parser(0, lang)
  if not parser then return nil end
  local trees = parser:parse()
  if not trees or #trees == 0 then return nil end
  return trees[1]:root()
end

local FUNC_PATTERNS = {
  lua = "((function_declaration) @func)",
  python = "((function_definition) @func)",
  javascript = "((function_declaration) @func)",
  typescript = "((function_declaration) @func)",
  bash = "((function_definition) @func)",
  markdown = "((section) @sec)",
}

local CLASS_PATTERNS = {
  lua = "((class_declaration) @class)",
  python = "((class_definition) @class)",
  javascript = "((class_declaration) @class)",
  typescript = "((class_declaration) @class)",
}

local BLOCK_PATTERNS = {
  lua = "((block) @block)",
  python = "((block) @block)",
  javascript = "((block) @block)",
  typescript = "((block) @block)",
  bash = "((compound_statement) @block)",
}

local METHOD_PATTERNS = {
  lua = "((method_declaration) @method)",
  python = "((function_definition) @method)",
  javascript = "((method_definition) @method)",
  typescript = "((method_definition) @method)",
}

local LOOP_PATTERNS = {
  lua = "((for_statement) @loop) ((while_statement) @loop)",
  python = "((for_statement) @loop) ((while_statement) @loop)",
  javascript = "((for_statement) @loop) ((while_statement) @loop) ((do_statement) @loop)",
  typescript = "((for_statement) @loop) ((while_statement) @loop) ((do_statement) @loop)",
  bash = "((for_statement) @loop) ((while_statement) @loop)",
}

local IF_PATTERNS = {
  lua = "((if_statement) @if) ((else_clause) @else)",
  python = "((if_statement) @if) ((elif_clause) @elif) ((else_clause) @else)",
  javascript = "((if_statement) @if) ((else_clause) @else)",
  typescript = "((if_statement) @if) ((else_clause) @else)",
  bash = "((if_statement) @if) ((else_clause) @else)",
}

local function jump_nodes(pattern, direction)
  local row = direction == "prev" and vim.fn.line(".") - 2 or vim.fn.line(".")
  local lang = vim.bo.filetype
  local pat = pattern[lang]
  if not pat then return end
  local root = get_tree_root(lang)
  if not root then return end
  local ok, squery = pcall(vim.treesitter.query.parse, lang, pat)
  if not ok then return end
  local nodes = {}
  for _, n in squery:iter_captures(root, 0) do
    table.insert(nodes, { row = n:range(), node = n })
  end
  table.sort(nodes, function(a, b) return a.row < b.row end)
  if direction == "prev" then
    for i = #nodes, 1, -1 do
      if nodes[i].row <= row then
        vim.api.nvim_win_set_cursor(0, { nodes[i].row + 1, 0 })
        return
      end
    end
  else
    for i = 1, #nodes do
      if nodes[i].row >= row then
        vim.api.nvim_win_set_cursor(0, { nodes[i].row + 1, 0 })
        return
      end
    end
  end
end

local function get_node_text(obj)
  local start_row, start_col, end_row, end_col = obj:range()
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  if #lines == 0 then return "" end
  lines[#lines] = lines[#lines]:sub(1, end_col)
  lines[1] = lines[1]:sub(start_col + 1)
  return table.concat(lines, "\n")
end

vim.keymap.set("n", "[f", function() jump_nodes(FUNC_PATTERNS, "prev") end, { desc = "Previous function" })
vim.keymap.set("n", "]f", function() jump_nodes(FUNC_PATTERNS, "next") end, { desc = "Next function" })
vim.keymap.set("n", "[c", function() jump_nodes(CLASS_PATTERNS, "prev") end, { desc = "Previous class" })
vim.keymap.set("n", "]c", function() jump_nodes(CLASS_PATTERNS, "next") end, { desc = "Next class" })
vim.keymap.set("n", "[{", function() jump_nodes(BLOCK_PATTERNS, "prev") end, { desc = "Previous block" })
vim.keymap.set("n", "]}", function() jump_nodes(BLOCK_PATTERNS, "next") end, { desc = "Next block" })
vim.keymap.set("n", "[m", function() jump_nodes(METHOD_PATTERNS, "prev") end, { desc = "Previous method" })
vim.keymap.set("n", "]m", function() jump_nodes(METHOD_PATTERNS, "next") end, { desc = "Next method" })
vim.keymap.set("n", "[l", function() jump_nodes(LOOP_PATTERNS, "prev") end, { desc = "Previous loop" })
vim.keymap.set("n", "]l", function() jump_nodes(LOOP_PATTERNS, "next") end, { desc = "Next loop" })
vim.keymap.set("n", "[i", function() jump_nodes(IF_PATTERNS, "prev") end, { desc = "Previous if/else" })
vim.keymap.set("n", "]i", function() jump_nodes(IF_PATTERNS, "next") end, { desc = "Next if/else" })

vim.keymap.set("n", "gs", function()
  local row = vim.fn.line(".") - 1
  local lang = vim.bo.filetype
  local pat = FUNC_PATTERNS[lang]
  if not pat then return end
  local root = get_tree_root(lang)
  if not root then return end
  local ok, squery = pcall(vim.treesitter.query.parse, lang, pat)
  if not ok then return end
  for _, n in squery:iter_captures(root, 0) do
    local srow, scol, erow, ecol = n:range()
    if srow <= row and row <= erow then
      local text = get_node_text(n)
      if text and text ~= "" then
        local preview = text:gsub("\n", " "):sub(1, 80)
        vim.notify("Function: " .. preview .. (text:len() > 80 and " ..." or ""), vim.log.levels.INFO)
      end
      return
    end
  end
end, { desc = "Show symbol under cursor" })

M.install_parsers()

return M