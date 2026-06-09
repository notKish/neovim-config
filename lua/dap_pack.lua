-- DAP debugging: Python, JS/TS, Java (jdtls).
-- Adapter paths come from Nix-generated ~/.local/share/nvim/dap_paths.lua (or NVIM_DAP_* env vars).
-- Keymaps: <leader>d* (see keymaps.lua)
local M = {}

local nix_paths = (function()
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "dap_paths.lua")
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  local ok, cfg = pcall(loadfile, path)
  if not ok or type(cfg) ~= "function" then
    return {}
  end
  local loaded_ok, loaded = pcall(cfg)
  return loaded_ok and loaded or {}
end)()

local function env_path(name)
  local value = vim.env[name]
  if value and value ~= "" then
    return value
  end
  return nil
end

local function resolve_path(nix_key, env_name, fallback)
  local from_nix = nix_paths[nix_key]
  if from_nix and from_nix ~= "" then
    if nix_key == "java_debug_dir" then
      if vim.fn.isdirectory(from_nix) == 1 then
        return from_nix
      end
    elseif vim.fn.filereadable(from_nix) == 1 then
      return from_nix
    end
  end

  local from_env = env_path(env_name)
  if from_env and from_env ~= "" then
    return from_env
  end

  return fallback
end

local function java_debug_dir()
  return resolve_path(
    "java_debug_dir",
    "NVIM_DAP_JAVA_DEBUG_DIR",
    vim.fs.joinpath(vim.fn.stdpath("data"), "dap-adapters", "java-debug")
  )
end

function M.jdtls_bundles()
  local pattern = java_debug_dir() .. "/com.microsoft.java.debug.plugin-*.jar"
  local jars = vim.fn.glob(pattern, false, true)
  if type(jars) == "string" then
    jars = jars ~= "" and { jars } or {}
  end
  return vim.tbl_filter(function(path)
    return path ~= "" and vim.fn.filereadable(path) == 1
  end, jars or {})
end

local function notify_missing(msg)
  vim.notify(msg .. "\nRun: darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro", vim.log.levels.WARN)
end

local function setup_signs()
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "DebugLine", numhl = "" })
end

local function python_executable()
  local python = resolve_path("python", "NVIM_DAP_PYTHON", nil)
  if python then
    return python
  end

  local uv = vim.fn.exepath("uv")
  if uv ~= "" then
    return uv
  end

  python = vim.fn.exepath("python3")
  if python ~= "" then
    return python
  end
  return "python3"
end

local function setup_python()
  local ok, dap_python = pcall(require, "dap-python")
  if not ok then
    return
  end

  dap_python.setup(python_executable())

  local dap = require("dap")
  dap.configurations.python = dap.configurations.python or {}
  table.insert(dap.configurations.python, {
    type = "python",
    request = "launch",
    name = "Python: current file",
    program = "${file}",
    console = "integratedTerminal",
    justMyCode = true,
  })
end

local function setup_js()
  local ok, js = pcall(require, "dap-vscode-js")
  if not ok then
    return
  end

  local js_server = resolve_path("js_debug", "NVIM_DAP_JS_DEBUG", nil)
  local js_opts = { adapters = { "pwa-node", "pwa-chrome" } }

  if js_server then
    local node = vim.fn.exepath("node")
    js_opts.debugger_cmd = { node ~= "" and node or "node", js_server }
  else
    local js_debug_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "dap-adapters", "js-debug")
    if vim.fn.isdirectory(js_debug_dir) == 0 then
      notify_missing("JS debugger not found")
      return
    end
    js_opts.debugger_path = js_debug_dir
  end

  js.setup(js_opts)

  local dap = require("dap")
  for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Node: current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        console = "integratedTerminal",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Node: npm test",
        runtimeExecutable = "npm",
        runtimeArgs = { "test" },
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
      },
    }
  end
end

local function setup_java()
  local bundles = M.jdtls_bundles()
  if #bundles == 0 then
    notify_missing("Java debug bundles not found in " .. java_debug_dir())
    return
  end

  local ok, jdtls_dap = pcall(require, "jdtls.dap")
  if ok then
    jdtls_dap.setup_dap({ hotcodereplace = "auto" })
  end
end

local function setup_ui()
  local ok, dapui = pcall(require, "dapui")
  if not ok then
    return
  end

  dapui.setup({
    icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
    controls = {
      element = "repl",
      enabled = true,
      icons = {
        disconnect = "⏹",
        pause = "⏸",
        play = "▶",
        run_last = "↻",
        step_back = "⏮",
        step_into = "↓",
        step_out = "↑",
        step_over = "→",
        terminate = "✕",
      },
    },
  })

  local dap = require("dap")
  local dapui_open = function() dapui.open({}) end
  local dapui_close = function() dapui.close({}) end

  dap.listeners.after.event_initialized["dapui"] = dapui_open
  dap.listeners.before.event_terminated["dapui"] = dapui_close
  dap.listeners.before.event_exited["dapui"] = dapui_close
end

function M.setup()
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("nvim-dap failed to load", vim.log.levels.ERROR)
    return
  end

  setup_signs()
  setup_ui()
  setup_python()
  setup_js()
  setup_java()

  vim.api.nvim_create_user_command("DapHealth", function()
    local python = python_executable()
    local debugpy_ok = false
    if vim.fn.fnamemodify(python, ":t") == "uv" then
      debugpy_ok = vim.fn.system({ python, "run", "--with", "debugpy", "python", "-c", "import debugpy" }) == ""
    else
      debugpy_ok = vim.fn.system({ python, "-c", "import debugpy" }) == ""
    end

    local js_server = resolve_path("js_debug", "NVIM_DAP_JS_DEBUG", nil)
    local js_status = js_server or "missing — rebuild Nix config"

    local lines = {
      "DAP adapter status:",
      ("  Python: %s (%s)"):format(python, debugpy_ok and "debugpy ok" or "debugpy missing"),
      ("  Java bundles: %d jar(s) in %s"):format(#M.jdtls_bundles(), java_debug_dir()),
      ("  JS debugger: %s"):format(js_status),
      ("  dap_paths.lua: %s"):format(nix_paths.python and "loaded" or "missing — rebuild Nix config"),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Check DAP adapter installation" })
end

M.setup()

return M
