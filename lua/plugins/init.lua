-- Neovim 0.12+ vim.pack (:h vim.pack). Plugins install under stdpath("data")/site/pack/core/opt/<name>.
-- That .../site directory must be on 'packpath' (:h vim.pack-directory). Nix/--clean setups sometimes omit it until created.
-- This file is the pack registry only; per-plugin config lives in lua/plugins/<name>.lua.
-- Treesitter config (parsers, text objects) lives in lua/plugins/treesitter.lua.
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
  -- LeetCode / DSA practice (kawre/leetcode.nvim); pickers: plenary + nui; uses mini.pick if :Pick exists
  { src = gh("nvim-lua/plenary.nvim"), version = "HEAD" },
  { src = gh("MunifTanjim/nui.nvim"), version = "HEAD" },
  { src = gh("kawre/leetcode.nvim"), version = "HEAD" },
  -- AI chat, inline, agents (olimorris/codecompanion.nvim)
  { src = gh("olimorris/codecompanion.nvim"), version = vim.version.range("^19.0.0") },
  -- Debugging (DAP): Python, JS/TS, Java (via jdtls)
  { src = gh("nvim-neotest/nvim-nio"), version = "HEAD" },
  { src = gh("mfussenegger/nvim-dap"), version = "HEAD" },
  { src = gh("rcarriga/nvim-dap-ui"), version = "HEAD" },
  { src = gh("mfussenegger/nvim-dap-python"), version = "HEAD" },
  { src = gh("mxsdev/nvim-dap-vscode-js"), version = "HEAD" },
}, { confirm = false, load = true })
if not pack_ok then
  vim.notify(
    "vim.pack.add failed (need git on PATH; see :h vim.pack): " .. tostring(pack_err),
    vim.log.levels.ERROR
  )
  return
end
