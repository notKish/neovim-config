-- Palette matches built-in `:colorscheme retrobox` (sampled via nvim_get_hl).
-- Base UI stays from retrobox; this file layers treesitter, statusline, tabline, LSP refs.
local M = {}

---@type table<string, string>
local p = {
  fg = "#ebdbb2", -- Normal
  identifier = "#83a598", -- Identifier
  emphasis = "#fb5944", -- Statement (keywords)
  operator = "#8ec07c", -- Operator (same hue as PreProc in retrobox)
  comment = "#928374",
  string = "#b8bb26", -- String, Function
  function_hl = "#b8bb26",
  type = "#fabd2f",
  constant = "#d3869b",
  special = "#fe8019",
  preproc = "#8ec07c",
  linenr = "#7c6f64",
  bg = "#1c1c1c",
  pmenu = "#3c3836",
  visual = "#2a405a",
  tabline_bg = "#767676",
  tabline_fg = "#000000",
  tabline_sel_bg = "#c6c6c6",
  tabline_sel_fg = "#000000",
}

local function set_hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function apply_specs(specs)
  for _, row in ipairs(specs) do
    set_hl(row[1], row[2])
  end
end

function M.apply()
  apply_specs({
    -- treesitter → retrobox classic groups
    { "@keyword", { fg = p.emphasis, bold = true } },
    { "@function", { fg = p.function_hl } },
    { "@function.builtin", { fg = p.function_hl, italic = true } },
    { "@function.macro", { fg = p.preproc, bold = true } },
    { "@type", { fg = p.type } },
    { "@type.builtin", { fg = p.type, italic = true } },
    { "@type.definition", { fg = p.type, underline = true } },
    { "@variable", { fg = p.identifier } },
    { "@variable.builtin", { fg = p.constant } },
    { "@string", { fg = p.string } },
    { "@string.escape", { fg = p.special, bold = true } },
    { "@string.regex", { fg = p.string, italic = true } },
    { "@number", { fg = p.constant } },
    { "@number.float", { fg = p.constant } },
    { "@boolean", { fg = p.constant } },
    { "@comment", { fg = p.comment, italic = true } },
    { "@comment.doc", { fg = p.comment, italic = true } },
    { "@operator", { fg = p.operator, bold = true } },
    { "@punctuation", { fg = p.fg } },
    { "@punctuation.bracket", { fg = p.fg } },
    { "@punctuation.delimiter", { fg = p.fg } },
    { "@constant", { fg = p.constant } },
    { "@constant.builtin", { fg = p.constant, bold = true } },
    { "@constant.macro", { fg = p.preproc, underline = true } },
    { "@attribute", { fg = p.type } },
    { "@attribute.builtin", { fg = p.type, italic = true } },
    { "@field", { fg = p.special } },
    { "@field.property", { fg = p.special } },
    { "@parameter", { fg = p.identifier, italic = true } },
    { "@parameter.reference", { fg = p.identifier } },
    { "@namespace", { fg = p.fg } },
    { "@module", { fg = p.fg } },
    { "@label", { fg = p.preproc } },
    { "@tag", { fg = p.type } },
    { "@tag.delimiter", { fg = p.special } },
    { "@tag.attribute", { fg = p.string } },
    { "@regex", { fg = p.string } },
    { "@escape", { fg = p.special, bold = true } },
    { "@special", { fg = p.special } },
    { "@special.char", { fg = p.special } },
    { "@special.url", { fg = p.comment, underline = true } },
    { "@text", { fg = p.fg } },
    { "@text.strong", { fg = p.emphasis, bold = true } },
    { "@text.emphasis", { fg = p.fg, italic = true } },
    { "@text.underline", { fg = p.fg, underline = true } },
    { "@text.strike", { fg = p.linenr, strikethrough = true } },
    { "@text.title", { fg = p.preproc, bold = true } },
    { "@text.title.1", { fg = p.preproc, bold = true } },
    { "@text.title.2", { fg = p.comment, bold = true } },
    { "@text.title.3", { fg = p.type, bold = true } },
    { "@text.title.4", { fg = p.string, bold = true } },
    { "@text.title.5", { fg = p.constant, bold = true } },
    { "@text.uri", { fg = p.comment, underline = true } },
    { "@text.literal", { fg = p.string } },
    { "@text.math", { fg = p.constant } },
    { "@text.note", { fg = p.comment, italic = true } },
    { "@text.warning", { fg = p.string, bold = true } },
    { "@text.danger", { fg = p.constant, bold = true } },
    { "@text.diff.add", { fg = p.type } },
    { "@text.diff.delete", { fg = p.constant } },
    { "@symbol", { fg = p.preproc } },
    { "@symbol.bracket", { fg = p.special } },
    { "@symbol.inner", { fg = p.comment } },
    { "@symbol.outer", { fg = p.comment, bold = true } },
    { "TSNone", { fg = p.fg } },
    { "LspReferenceText", { bg = p.visual } },
    { "LspReferenceRead", { link = "LspReferenceText" } },
    { "LspReferenceWrite", { link = "LspReferenceText" } },
    { "StatuslineGit", { fg = p.type, bg = p.pmenu } },
    { "StatuslineGitDirty", { fg = p.constant, bg = p.pmenu } },
    { "StatuslineMode", { fg = p.bg, bg = p.string, bold = true } },
    { "StatuslineReadonly", { fg = p.string, bg = p.pmenu } },
    { "StatuslineInfo", { fg = p.comment, bg = p.pmenu } },
    { "StatuslineSubtle", { fg = p.linenr, bg = p.pmenu, bold = true } },
    { "StatuslineSearch", { fg = p.preproc, bg = p.pmenu } },
    { "TabLine", { fg = p.tabline_fg, bg = p.tabline_bg } },
    { "TabLineSel", { fg = p.tabline_sel_fg, bg = p.tabline_sel_bg, bold = true } },
    { "TabLineFill", { fg = p.tabline_fg, bg = p.tabline_bg } },
    { "TabLineMod", { fg = p.constant, bg = p.tabline_bg, bold = true } },
    -- Floats (leetcode.nvim description uses Normal:NormalFloat — avoid grey-on-grey)
    { "NormalFloat", { fg = p.fg, bg = p.pmenu } },
    { "FloatBorder", { fg = p.linenr, bg = p.pmenu } },
  })
end

M.hl = set_hl

M.apply()
return M
