local map = vim.keymap.set

vim.opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy" }
vim.opt.pumheight = 12
vim.opt.shortmess:append("c")

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
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", false)
end, { desc = "Trigger completion" })

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
