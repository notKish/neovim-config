-- mini.pick file finder UI (vim.pack). Replaces vim.ui.select() with proper fuzzy picker.
local mini_pick = require("mini.pick")

mini_pick.setup({
  options = {
    use_cache = true,
  },
  mappings = {
    caret_left  = '<Left>',
    caret_right = '<Right>',
    choose      = '<CR>',
    choose_in_split   = '<C-s>',
    choose_in_tabpage = '<C-t>',
    choose_in_vsplit  = '<C-v>',
    move_down   = '<C-j>',
    move_up     = '<C-k>',
    scroll_down = '<C-d>',
    scroll_up   = '<C-u>',
    stop        = '<Esc>',
    toggle_info = '<Tab>',
    toggle_preview = '<C-p>',
  },
  window = {
    config = {
      border = 'rounded',
    },
    prompt_prefix = '> ',
  },
})

-- Override vim.ui.select to use mini.pick for a better UI
vim.ui.select = mini_pick.ui_select
