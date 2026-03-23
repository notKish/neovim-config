return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  cmd = { "TSUpdate", "TSUpdateSync" },
  opts = {
    ensure_installed = {
      "lua",
      "python",
      "javascript",
      "typescript",
      "bash",
      "markdown",
      "json",
      "toml",
      "c",
      "vim",
      "vimdoc",
    },
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<CR>",
        node_incremental = "<CR>",
        scope_incremental = "<S-CR>",
        node_decremental = "<BS>",
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["ap"] = "@parameter.outer",
          ["ip"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]f"] = "@function.outer",
          ["]c"] = "@class.outer",
          ["]m"] = "@method.outer",
        },
        goto_next_end = {
          ["]F"] = "@function.outer",
          ["]C"] = "@class.outer",
          ["]M"] = "@method.outer",
        },
        goto_previous_start = {
          ["[f"] = "@function.outer",
          ["[c"] = "@class.outer",
          ["[m"] = "@method.outer",
        },
        goto_previous_end = {
          ["[F"] = "@function.outer",
          ["[C"] = "@class.outer",
          ["[M"] = "@method.outer",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          [">F"] = "@function.outer",
          [">C"] = "@class.outer",
          [">m"] = "@method.outer",
        },
        swap_previous = {
          ["<F"] = "@function.outer",
          ["<C"] = "@class.outer",
          ["<m"] = "@method.outer",
        },
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
