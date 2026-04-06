-- Native insert completion: LSP (vim.lsp.completion) + mini.snippets LSP (friendly-snippets); expand/jump via vim.snippet.
local map = vim.keymap.set

-- "popup": extra docs/detail (LSP resolve) for the highlighted pum item (:h completeopt).
-- With "noselect", no row is highlighted until you <C-n>/<C-p> — move once to show import/module "detail" in the popup.
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy" }
vim.opt.pumheight = 12
vim.opt.pumborder = "rounded"
vim.opt.shortmess:append("c")

-- Do NOT set 'autocomplete' here. That option triggers <C-n>-style keyword completion (from 'complete'
-- sources like buffer words) on TextChangedI, which opens the pum before InsertCharPre fires.
-- vim.lsp.completion.enable autotrigger (InsertCharPre) early-returns when pumvisible() != 0, so LSP
-- and snippets would never be queried after the first character typed. Use autotrigger=true only
-- (set in lsp.lua LspAttach, with triggerChars extended to alnum via merge_keyword_completion_triggers).

local function has_snippet(direction)
  if not vim.snippet or type(vim.snippet.active) ~= "function" then
    return false
  end
  local ok, active = pcall(vim.snippet.active, { direction = direction })
  return ok and active
end

local function jump_snippet(direction)
  if vim.snippet and type(vim.snippet.jump) == "function" then
    pcall(vim.snippet.jump, direction)
  end
end

map("i", "<C-Space>", function()
  if vim.lsp.completion and vim.lsp.completion.get then
    vim.lsp.completion.get()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", false)
  end
end, { desc = "Trigger LSP completion" })

map("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end
  return "<CR>"
end, { expr = true, desc = "Accept completion item" })

map("i", "<Tab>", function()
  if has_snippet(1) then
    jump_snippet(1)
    return ""
  end
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end
  return "<Tab>"
end, { expr = true, desc = "Next completion/snippet jump" })

map("i", "<S-Tab>", function()
  if has_snippet(-1) then
    jump_snippet(-1)
    return ""
  end
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  end
  return "<S-Tab>"
end, { expr = true, desc = "Prev completion/snippet jump" })
