return {
  "saghen/blink.cmp",
  version = "*",
  lazy = false,
  dependencies = {
    "rafamadriz/friendly-snippets",
    "L3MON4D3/LuaSnip",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = { "select_and_accept" },
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
    completion = {
      menu = {
        border = "rounded",
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    snippets = {
      storage = "luasnip",
    },
  },
}
