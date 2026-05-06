-- kawre/leetcode.nvim — LeetCode / DSA practice inside Neovim (:Leet)
-- Requires pick_pack.lua first so mini.pick registers :Pick (leetcode.nvim mini-picker).
--
-- Default plugin theme uses Conceal for body text + NormalFloat window → grey on grey on retrobox.
-- Overrides use the same palette as lua/highlights.lua (retrobox).
local lc_fg = "#ebdbb2"
local lc_muted = "#bdae93"
local lc_comment = "#928374"
local lc_bg = "#1c1c1c"
local ok, err = pcall(function()
  require("leetcode").setup({
    plugins = {
      non_standalone = true,
    },
    picker = {
      provider = "mini-picker",
    },
    -- Change via :Leet lang when needed
    lang = "python3",
    theme = {
      [""] = { fg = lc_fg },
      normal = { fg = lc_fg },
      alt = { fg = lc_muted },
      indent = { fg = lc_comment },
      code = { fg = "#fabd2f", bg = lc_bg },
      example = { fg = "#83a598" },
      constraints = { fg = "#8ec07c" },
      header = { fg = "#fe8019", bold = true },
      followup = { fg = "#d3869b", bold = true },
      list = { fg = "#fe8019" },
      ref = { fg = "#83a598" },
      link = { fg = "#b8bb26", underline = true },
      all_alt = { fg = lc_muted },
    },
  })
end)
if not ok then
  vim.notify("leetcode.nvim failed to load: " .. tostring(err), vim.log.levels.ERROR)
end
