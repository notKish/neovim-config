-- Neovim 0.12+ vim.pack (:h vim.pack). Only plugins that have no core equivalent here:
-- extra treesitter parsers + queries beyond bundled C/Lua/Markdown/Vim/Vimdoc (:h treesitter-parsers)
local gh = function(repo)
  return "https://github.com/" .. repo
end

for _, plug in ipairs({
  "gzip",
  "tar",
  "tarPlugin",
  "tohtml",
  "tutor",
  "zip",
  "zipPlugin",
}) do
  vim.g["loaded_" .. plug] = 1
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d.spec.name ~= "nvim-treesitter" then
      return
    end
    if d.kind ~= "install" and d.kind ~= "update" then
      return
    end
    vim.schedule(function()
      pcall(vim.cmd.TSUpdate)
    end)
  end,
})

vim.pack.add({
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "6620ae1c44dfa8623b22d0cbf873a9e8d073b849" },
}, { confirm = false })

local parser_install_dir = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "site")
require("nvim-treesitter").setup({
  install_dir = parser_install_dir,
})

local ts_langs = {
  "lua",
  "python",
  "javascript",
  "typescript",
  "tsx",
  "bash",
  "markdown",
  "json",
  "toml",
  "c",
  "vim",
  "vimdoc",
}
require("nvim-treesitter").install(ts_langs)

local ts_filetypes = {
  "lua",
  "python",
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
  "vim",
  "vimdoc",
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = ts_filetypes,
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
    if vim.bo[ev.buf].indentexpr == "" then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
