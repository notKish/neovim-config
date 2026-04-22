-- Neovim 0.12+ vim.pack (:h vim.pack). Plugins install under stdpath("data")/site/pack/core/opt/<name>.
-- That .../site directory must be on 'packpath' (:h vim.pack-directory). Nix/--clean setups sometimes omit it until created.
-- There is no lua/plugins/ folder (that was lazy.nvim); specs live here only.
local gh = function(repo)
  return "https://github.com/" .. repo
end

local data_site = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "site"))
if vim.fn.isdirectory(data_site) == 0 then
  vim.fn.mkdir(data_site, "p")
end
if not vim.o.packpath:find(data_site, 1, true) then
  vim.opt.packpath:prepend(data_site)
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

local pack_ok, pack_err = pcall(vim.pack.add, {
  { src = gh("rafamadriz/friendly-snippets"), version = "6cd7280adead7f586db6fccbd15d2cac7e2188b9" },
  { src = gh("echasnovski/mini.nvim"), version = "a995fe9cd4193fb492b5df69175a351a74b3d36b" },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "6620ae1c44dfa8623b22d0cbf873a9e8d073b849" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "HEAD" },
  { src = gh("mfussenegger/nvim-jdtls"), version = "HEAD" },
}, { confirm = false, load = true })
if not pack_ok then
  vim.notify(
    "vim.pack.add failed (need git on PATH; see :h vim.pack): " .. tostring(pack_err),
    vim.log.levels.ERROR
  )
  return
end

local parser_install_dir = data_site
local ts_ok, ts_err = pcall(function()
  require("nvim-treesitter").setup({
    install_dir = parser_install_dir,
  })
  require("nvim-treesitter").install({
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
    "cpp",
    "vim",
    "vimdoc",
  })
end)
if not ts_ok then
  vim.notify("nvim-treesitter failed to load: " .. tostring(ts_err), vim.log.levels.ERROR)
  return
end

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
  "cpp",
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
