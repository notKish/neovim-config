-- nvim-treesitter: parser install/start, indentexpr, text objects.
-- Pack is installed by the registry in lua/plugins/init.lua; this file configures it.
-- Loaded from init.lua right after the registry.
local data_site = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "site"))
local parser_install_dir = data_site
local ts_ok, ts_err = pcall(function()
  require("nvim-treesitter").setup({
    install_dir = parser_install_dir,
  })
  require("nvim-treesitter").install({
    "lua",
    "python",
    "java",
    "javascript",
    "typescript",
    "tsx",
    "bash",
    "markdown",
    "json",
    "toml",
    "html",
    "c",
    "cpp",
    "vim",
    "vimdoc",
    "yaml",
  })
end)
if not ts_ok then
  vim.notify("nvim-treesitter failed to load: " .. tostring(ts_err), vim.log.levels.ERROR)
  return
end

local ts_filetypes = {
  "lua",
  "python",
  "java",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "bash",
  "sh",
  "markdown",
  "json",
  "jsonc",
  "toml",
  "c",
  "cpp",
  "arduino",
  "vim",
  "vimdoc",
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = ts_filetypes,
  callback = function(ev)
    -- .ino/.pde buffers get filetype `arduino`, but the C++ parser handles them.
    local lang = ev.ft == "arduino" and "cpp" or nil
    pcall(vim.treesitter.start, ev.buf, lang)
    if vim.bo[ev.buf].indentexpr == "" then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Treesitter text objects configuration
local ts_textobjects_ok, ts_textobjects = pcall(require, "nvim-treesitter-textobjects")
if ts_textobjects_ok then
  ts_textobjects.setup({
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
        ["]a"] = "@parameter.inner",
        ["]i"] = "@conditional.outer",
        ["]l"] = "@loop.outer",
      },
      goto_next_end = {
        ["]F"] = "@function.outer",
        ["]C"] = "@class.outer",
        ["]I"] = "@conditional.outer",
        ["]L"] = "@loop.outer",
      },
      goto_previous_start = {
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
        ["[a"] = "@parameter.inner",
        ["[i"] = "@conditional.outer",
        ["[l"] = "@loop.outer",
      },
      goto_previous_end = {
        ["[F"] = "@function.outer",
        ["[C"] = "@class.outer",
        ["[I"] = "@conditional.outer",
        ["[L"] = "@loop.outer",
      },
    },
  })
end
