local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function project_root()
  local root = vim.fs.root(0, { ".git" })
  return root or vim.fn.getcwd()
end

local function parse_vimgrep(lines)
  local items = {}
  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
    if file and lnum and col then
      table.insert(items, {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      })
    end
  end
  return items
end

function M.find_files()
  local root = project_root()
  local files = vim.fn.systemlist({ "rg", "--files", "--hidden", "--glob", "!.git", root })
  if vim.v.shell_error ~= 0 then
    notify("find_files: rg failed", vim.log.levels.ERROR)
    return
  end
  if #files == 0 then
    notify("No files found")
    return
  end

  vim.ui.select(files, { prompt = "Find files:" }, function(choice)
    if not choice then
      return
    end
    vim.cmd.edit(vim.fn.fnameescape(choice))
  end)
end

function M.live_grep()
  vim.ui.input({ prompt = "Live grep pattern: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end
    local root = project_root()
    local lines = vim.fn.systemlist({ "rg", "--vimgrep", "--smart-case", input, root })
    if vim.v.shell_error ~= 0 and #lines == 0 then
      notify("No matches")
      return
    end
    local items = parse_vimgrep(lines)
    vim.fn.setqflist({}, " ", {
      title = "live_grep: " .. input,
      items = items,
    })
    vim.cmd.copen()
  end)
end

function M.grep_word()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  local root = project_root()
  local lines = vim.fn.systemlist({ "rg", "--vimgrep", "--smart-case", word, root })
  if vim.v.shell_error ~= 0 and #lines == 0 then
    notify("No matches for: " .. word)
    return
  end
  local items = parse_vimgrep(lines)
  vim.fn.setqflist({}, " ", {
    title = "grep_word: " .. word,
    items = items,
  })
  vim.cmd.copen()
end

function M.help_tags()
  local tags = vim.fn.getcompletion("", "help")
  if #tags == 0 then
    notify("No help tags found", vim.log.levels.WARN)
    return
  end
  vim.ui.select(tags, { prompt = "Help tags:" }, function(choice)
    if not choice then
      return
    end
    vim.cmd.help(choice)
  end)
end

return M
