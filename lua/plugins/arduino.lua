-- Arduino workflow: arduino-cli compile/upload/monitor/board + LSP helpers.
-- Binaries come from Nix (arduino-cli + arduino-language-server in system-packages.nix).
-- Board cores are installed via arduino-cli (see doc/arduino-guide.txt).
-- Loaded from init.lua after plugins.dap; core/lsp.lua requires it lazily for the LSP setup.

local M = {}

local function cli_path()
  return vim.fn.exepath("arduino-cli")
end

local function notify_missing()
  vim.notify(
    "arduino-cli not found. Run: darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro",
    vim.log.levels.WARN
  )
end

-- Clang-style errorformat shared by :make (compile) and the upload quickfix.
local errorformat = "%f:%l:%c: %t%*[^:]: %m,%f:%l:%c: %m,%f:%l: %m"

-- Sketch root: first dir walking upward that holds sketch.yaml, .fqbn, .git, or a *.ino.
function M.project_root(start)
  if type(start) ~= "string" or start == "" then
    return nil
  end
  local dir = vim.fs.dirname(start)
  while dir and dir ~= "" and dir ~= "/" do
    for _, marker in ipairs({ "sketch.yaml", ".fqbn", ".git" }) do
      local path = vim.fs.joinpath(dir, marker)
      if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
        return dir
      end
    end
    if #vim.fn.glob(vim.fs.joinpath(dir, "*.ino"), false, true) > 0 then
      return dir
    end
    dir = vim.fs.dirname(dir)
  end
  return nil
end

local function sketch_yaml_value(root, key)
  local path = vim.fs.joinpath(root, "sketch.yaml")
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  for line in io.lines(path) do
    local value = line:match("^%s*" .. key .. "%s*:%s*(%S+)%s*$")
    if value then
      return value
    end
  end
  return nil
end

-- Resolve FQBN: sketch.yaml `default_fqbn` → project `.fqbn` file → optional prompt.
-- `allow_prompt` is true only for interactive commands; autocmd/LSP paths must
-- not block (vim.fn.input errors in headless/silent contexts and aborts the buffer open).
function M.fqbn(root, allow_prompt)
  local from_yaml = sketch_yaml_value(root, "default_fqbn")
  if from_yaml then
    return from_yaml
  end
  local dot_fqbn = vim.fs.joinpath(root, ".fqbn")
  if vim.fn.filereadable(dot_fqbn) == 1 then
    local fqbn = vim.fn.readfile(dot_fqbn)[1]
    if type(fqbn) == "string" and fqbn ~= "" then
      return fqbn
    end
  end
  if allow_prompt then
    local input = vim.fn.input("Arduino FQBN (e.g. arduino:avr:uno): ")
    if input ~= "" then
      vim.fn.writefile({ input }, dot_fqbn)
      return input
    end
  end
  return nil
end

-- Resolve serial port: sketch.yaml `default_port` → first board on `arduino-cli board list`.
function M.port(root)
  local from_yaml = sketch_yaml_value(root, "default_port")
  if from_yaml then
    return from_yaml
  end
  local cli = cli_path()
  if cli == "" then
    return nil
  end
  local out = vim.fn.systemlist({ cli, "board", "list" })
  for _, line in ipairs(out) do
    local port = line:match("(%S*%/dev/%S*)")
    if port then
      return port
    end
  end
  return nil
end

local function baudrate(root)
  return sketch_yaml_value(root, "default_baudrate") or "115200"
end

-- makeprg for this buffer; compile runs with the sketch dir as arduino-cli's target.
local function set_makeprg(root)
  local cli = cli_path()
  if cli == "" then
    return
  end
  local fqbn = M.fqbn(root)
  local sketch = vim.fn.fnameescape(root)
  if fqbn then
    vim.bo.makeprg = vim.fn.fnameescape(cli) .. " compile --fqbn " .. fqbn .. " " .. sketch
  else
    vim.bo.makeprg = vim.fn.fnameescape(cli) .. " compile " .. sketch
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "arduino",
  callback = function()
    vim.bo.errorformat = errorformat
    local root = M.project_root(vim.api.nvim_buf_get_name(0))
    if root then
      set_makeprg(root)
    end
  end,
})

function M.compile()
  local root = M.project_root(vim.api.nvim_buf_get_name(0))
  if not root then
    vim.notify("No Arduino sketch detected (no .ino/sketch.yaml/.fqbn found)", vim.log.levels.WARN)
    return
  end
  if cli_path() == "" then
    notify_missing()
    return
  end
  local fqbn = M.fqbn(root, true)
  if not fqbn then
    return
  end
  set_makeprg(root)
  vim.cmd("copen")
  vim.cmd("make!")
end

function M.upload()
  local root = M.project_root(vim.api.nvim_buf_get_name(0))
  if not root then
    vim.notify("No Arduino sketch detected (no .ino/sketch.yaml/.fqbn found)", vim.log.levels.WARN)
    return
  end
  local cli = cli_path()
  if cli == "" then
    notify_missing()
    return
  end
  local fqbn = M.fqbn(root, true)
  if not fqbn then
    return
  end
  local port = M.port(root)
  if not port then
    port = vim.fn.input("Serial port (e.g. /dev/cu.usbmodem14101): ")
    if port == "" then
      vim.notify("No port — connect a board or set default_port in sketch.yaml", vim.log.levels.WARN)
      return
    end
  end
  local lines = {}
  local job = vim.fn.jobstart({ cli, "upload", "--fqbn", fqbn, "--port", port, root }, {
    on_stdout = function(_, data)
      for _, l in ipairs(data) do
        if l ~= "" then
          table.insert(lines, l)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, l in ipairs(data) do
        if l ~= "" then
          table.insert(lines, l)
        end
      end
    end,
    on_exit = function(_, code)
      vim.fn.setqflist({}, "r", { title = "Arduino upload", lines = lines, efm = errorformat })
      vim.cmd("copen")
      vim.notify("arduino-cli upload exited " .. code, code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    end,
  })
  if job == 0 then
    vim.notify("Failed to start arduino-cli upload", vim.log.levels.ERROR)
  end
end

function M.monitor()
  local root = M.project_root(vim.api.nvim_buf_get_name(0))
  if not root then
    vim.notify("No Arduino sketch detected (no .ino/sketch.yaml/.fqbn found)", vim.log.levels.WARN)
    return
  end
  local cli = cli_path()
  if cli == "" then
    notify_missing()
    return
  end
  local port = M.port(root)
  if not port then
    port = vim.fn.input("Serial port (e.g. /dev/cu.usbmodem14101): ")
    if port == "" then
      return
    end
  end
  vim.cmd("botright 15split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = "nofile"
  vim.fn.termopen({ cli, "monitor", "--port", port, "--config", "baudrate=" .. baudrate(root) }, {
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

function M.board()
  local root = M.project_root(vim.api.nvim_buf_get_name(0))
  if not root then
    vim.notify("No Arduino sketch detected (no .ino/sketch.yaml/.fqbn found)", vim.log.levels.WARN)
    return
  end
  local cli = cli_path()
  if cli == "" then
    notify_missing()
    return
  end
  local out = vim.fn.systemlist({ cli, "board", "listall" })
  local choices = {}
  for _, line in ipairs(out) do
    local fqbn = line:match("(%S+:%S+:%S+)")
    if fqbn then
      choices[#choices + 1] = { fqbn = fqbn, line = line }
    end
  end
  if #choices == 0 then
    vim.notify(
      "No boards found — run: arduino-cli core update-index && arduino-cli core install arduino:avr",
      vim.log.levels.WARN
    )
    return
  end
  vim.ui.select(choices, {
    prompt = "Arduino board (FQBN written to .fqbn)",
    format_item = function(item)
      return item.line
    end,
  }, function(choice)
    if choice then
      vim.fn.writefile({ choice.fqbn }, vim.fs.joinpath(root, ".fqbn"))
      vim.notify("FQBN " .. choice.fqbn .. " written to .fqbn", vim.log.levels.INFO)
    end
  end)
end

function M.health()
  local cli = cli_path()
  local als = vim.fn.exepath("arduino-language-server")
  local rebuild = "darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro"
  local lines = {
    "Arduino toolchain status:",
    ("  arduino-cli: %s"):format(cli ~= "" and cli or "MISSING — run: " .. rebuild),
    ("  arduino-language-server: %s"):format(als ~= "" and als or "MISSING — run: " .. rebuild),
  }
  if cli ~= "" then
    local cores = vim.tbl_filter(function(l)
      return l:find("^%S+:") ~= nil
    end, vim.fn.systemlist({ cli, "core", "list" }))
    if #cores == 0 then
      table.insert(lines, "  cores: none installed — run: arduino-cli core update-index && arduino-cli core install arduino:avr")
    else
      table.insert(lines, "  cores:")
      for _, c in ipairs(cores) do
        table.insert(lines, "    " .. c)
      end
    end
  end
  local root = M.project_root(vim.api.nvim_buf_get_name(0))
  table.insert(lines, ("  project: %s"):format(root or "no sketch detected in this buffer"))
  if root then
    table.insert(lines, ("  fqbn: %s"):format(M.fqbn(root) or "not set (use :ArduinoBoard)"))
    table.insert(lines, ("  port: %s"):format(M.port(root) or "not detected"))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("ArduinoCompile", function() M.compile() end, { desc = "Compile sketch with arduino-cli (quickfix)" })
vim.api.nvim_create_user_command("ArduinoUpload", function() M.upload() end, { desc = "Upload sketch to board" })
vim.api.nvim_create_user_command("ArduinoMonitor", function() M.monitor() end, { desc = "Open serial monitor (arduino-cli)" })
vim.api.nvim_create_user_command("ArduinoBoard", function() M.board() end, { desc = "Pick board FQBN and write .fqbn" })
vim.api.nvim_create_user_command("ArduinoHealth", function() M.health() end, { desc = "Check arduino-cli/ALS/cores/sketch status" })

return M
