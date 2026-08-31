local M = {}

M.config = {
  greeting = "hello from fundaments - default",
  show_timestamp = true,
  auto_welcome_lua = true
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})


  local function print_greeting()
    local message = M.config.greeting

    if M.config.show_timestamp then
      message = message .. " (loaded at: " .. os.date("%H:%M") .. " )"
    end
    print(message)
  end
  vim.keymap.set("n", "<leader>fg", print_greeting, { desc = "greets the user" })

  if M.config.auto_welcome_lua then
    local augroup = vim.api.nvim_create_augroup("fundamentalGroup", { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'lua',
      callback = function()
        print("you are editing a lua file :)")
      end,
      desc = "welcome message for the lua file"
    })
  end

  local function insert_line_count()
    local buff = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buff, 0, -1, false)
    local count = #lines

    local header = "---- Total lines: " .. count
    vim.api.nvim_buf_set_lines(buff, 0, 0, false, { header })
    print("inserted line count header")
  end

  vim.keymap.set('n', '<leader>fc', insert_line_count, { desc = "insert_line_count" })

  local function show_last_commit()
    local result = vim.fn.system('git log -1 --format="%h - %s"')

    if vim.v.shell_error == 0 then
      local commit_msg = result:gsub("\n$", "")
      print("last commit: " .. commit_msg)
    else
      print("not a git repo / git not found")
    end
  end
  vim.keymap.set('n', '<leader>gl', show_last_commit, { desc = "show last git commit" })
  print("setup complete with keymaps")
end

return M
