return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Telescope",
  version = false,
  opts = {
    defaults = {
      prompt_prefix = " ",
      selection_caret = " ",
      path_display = { "truncate" },
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
          results_width = 0.45,
        },
        width = 0.9,
        height = 0.85,
      },
      winblend = 0,
      border = true,
      borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      color_devicons = true,
      file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
      mappings = {
        i = {
          ["<CR>"] = "select_default",
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<C-f>"] = "preview_scrolling_down",
          ["<C-b>"] = "preview_scrolling_up",
          ["<Esc>"] = "close",
          ["<C-c>"] = "close",
        },
        n = {
          ["<CR>"] = "select_default",
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<C-f>"] = "preview_scrolling_down",
          ["<C-b>"] = "preview_scrolling_up",
          ["q"] = "close",
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        find_command = { "rg", "--files", "--hidden", "--glob", "!.git" },
      },
      live_grep = {
        additional_args = function()
          return { "--smart-case" }
        end,
      },
    },
  },
  keys = {
    { "<leader><space>", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
    { "<leader>?",       "<cmd>Telescope live_grep<cr>",   desc = "Live grep" },
    { "<leader>fw",      "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>fb",      "<cmd>Telescope buffers<cr>",     desc = "List buffers" },
    { "<leader>fh",      "<cmd>Telescope help_tags<cr>",   desc = "Help tags" },
  },
}
