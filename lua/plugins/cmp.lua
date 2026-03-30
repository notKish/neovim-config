return {
  "saghen/blink.cmp",
  version = "*",
  lazy = false,
  dependencies = {
    "L3MON4D3/LuaSnip",
  },
  opts = {
    keymap = {
      preset        = "none",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-k>"]     = { "show_documentation", "hide_documentation" },
      ["<C-b>"]     = { "scroll_documentation_up" },
      ["<C-f>"]     = { "scroll_documentation_down" },
      ["<C-p>"]     = { "show_signature", "hide_signature", "fallback" },
      ["<CR>"]      = { "accept", "fallback" },
      ["<Tab>"]     = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_forward()
          elseif cmp.is_visible() then
            return cmp.select_next()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"]   = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_backward()
          elseif cmp.is_visible() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      },
    },
    completion = {
      menu = {
        border = "rounded",
      },
      list = {
        selection = {
          preselect = false,   -- don't highlight first item automatically
          auto_insert = false, -- don't insert text while cycling
        },
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        buffer = {
          module = "blink.cmp.sources.buffer",
          min_keyword_length = 2,
          max_items = 8,
          score_offset = -3,
          opts = {
            get_bufnrs = function()
              return { vim.api.nvim_get_current_buf() }
            end,
          },
        },
      },
    },
    snippets = {
      preset = "luasnip",
    },
  },
}
