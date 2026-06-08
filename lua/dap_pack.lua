-- DAP debugging: Python, JS/TS, Java (jdtls).
-- Adapters are provided by Nix (~/.config/nix/modules/home/dap.nix) via NVIM_DAP_* env vars.
-- Keymaps: <leader>d* (see keymaps.lua)
local M = {}

local function env_path(name)
  local value = vim.env[name]
  if value and value ~= "" then
    return value
  end
  return nil
end

M.java_debug_dir = env_path("NVIM_DAP_JAVA_DEBUG_DIR")
  or vim.fs.joinpath(vim.fn.stdpath("data"), "dap-adapters", "java-debug")

function M.jdtls_bundles()
  local pattern = M.java_debug_dir .. "/com.microsoft.java.debug.plugin-*.jar"
  local jars = vim.fn.glob(pattern, false, true)
  if type(jars) == "string" then
    jars = jars ~= "" and { jars } or {}
  end
  return vim.tbl_filter(function(path)
    return path ~= "" and vim.fn.filereadable(path) == 1
  end, jars or {})
end

local function notify_missing(msg)
  vim.notify(msg .. "\nRebuild Nix config (~/.config/nix) to install DAP adapters.", vim.log.levels.WARN)
end

local function setup_signs()
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "DebugLine", numhl = "" })
end

local function python_executable()
  local nix_python = env_path("NVIM_DAP_PYTHON")
  if nix_python and vim.fn.filereadable(nix_python) == 1 then
    return nix_python
  end
  local uv = vim.fn.exepath("uv")
  if uv ~= "" then
    return uv
  end
  local python = vim.fn.exepath("python3")
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

  local js_server = env_path("NVIM_DAP_JS_DEBUG")
  local js_opts = { adapters = { "pwa-node", "pwa-chrome" } }

  if js_server and vim.fn.filereadable(js_server) == 1 then
    local node = vim.fn.exepath("node")
    js_opts.debugger_cmd = { node ~= "" and node or "node", js_server }
  else
    local js_debug_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "dap-adapters", "js-debug")
    if vim.fn.isdirectory(js_debug_dir) == 0 then
      notify_missing("JS debugger not found (set NVIM_DAP_JS_DEBUG or install manually)")
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
    notify_missing("Java debug bundles not found in " .. M.java_debug_dir)
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

    local js_server = env_path("NVIM_DAP_JS_DEBUG")
    local js_status = "missing — rebuild Nix config"
    if js_server and vim.fn.filereadable(js_server) == 1 then
      js_status = js_server
    end

    local lines = {
      "DAP adapter status:",
      ("  Python: %s (%s)"):format(python, debugpy_ok and "debugpy ok" or "debugpy missing"),
      ("  Java bundles: %d jar(s) in %s"):format(#M.jdtls_bundles(), M.java_debug_dir),
      ("  JS debugger: %s"):format(js_status),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Check DAP adapter installation" })
end

M.setup()

return M
