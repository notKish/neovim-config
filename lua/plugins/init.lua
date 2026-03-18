-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- ============================================================================
  -- Colorscheme
  -- ============================================================================
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night", transparent = true },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
      -- Keep transparency
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
    end,
  },

  -- ============================================================================
  -- Treesitter
  -- ============================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "go", "java", "javascript", "json",
          "lua", "markdown", "markdown_inline", "python", "query",
          "regex", "tsx", "typescript", "vim", "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ============================================================================
  -- Fuzzy finder
  -- ============================================================================
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({ "telescope" }) -- telescope-like layout

      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { desc = desc })
      end

      map("<leader>ff", fzf.files,            "Find files")
      map("<leader>fg", fzf.live_grep,        "Live grep")
      map("<leader>fb", fzf.buffers,          "Buffers")
      map("<leader>fh", fzf.help_tags,        "Help tags")
      map("<leader>fr", fzf.oldfiles,         "Recent files")
      map("<leader>fd", fzf.diagnostics_document, "Document diagnostics")
      map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
      map("<leader>fw", fzf.grep_cword,       "Grep word under cursor")
      map("<leader>fc", fzf.git_commits,      "Git commits")
      map("<leader>fC", fzf.git_bcommits,     "Buffer git commits")
    end,
  },

  -- ============================================================================
  -- Completion
  -- ============================================================================
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    opts = {
      keymap = {
        preset = "default",
        ["<Tab>"] = {
          function(cmp)
            if cmp.is_visible() then return cmp.select_next() end
          end,
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"] = {
          function(cmp)
            if cmp.is_visible() then return cmp.select_prev() end
          end,
          "snippet_backward",
          "fallback",
        },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-e>"] = { "hide" },
      },
      appearance = { use_nvim_cmp_as_default = false, nerd_font_variant = "mono" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        trigger = {
          prefetch_on_insert = false,
          show_on_trigger_character = false,
        },
      },
    },
  },

  -- ============================================================================
  -- Git signs in gutter
  -- ============================================================================
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buf)
        local gs = package.loaded.gitsigns
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end
        map("]h", gs.next_hunk, "Next hunk")
        map("[h", gs.prev_hunk, "Prev hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hr", gs.reset_hunk, "Reset hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
        map("<leader>hb", gs.blame_line, "Blame line")
      end,
    },
  },

  -- ============================================================================
  -- Mini plugins (pairs, surround, comments)
  -- ============================================================================
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "echasnovski/mini.surround",
    keys = { "sa", "sd", "sr", "sf", "sF", "sh", "sn" },
    opts = {},
  },
  {
    "echasnovski/mini.comment",
    keys = { "gc", { "gc", mode = "v" } },
    opts = {},
  },

}, {
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
