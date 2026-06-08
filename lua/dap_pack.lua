-- DAP debugging: Python, JS/TS, Java (jdtls).
-- Install adapters once: bash ~/.config/nvim/scripts/install-dap-adapters.sh
-- Keymaps: <leader>d* (see keymaps.lua)
local M = {}

local data = vim.fn.stdpath("data")
M.adapter_root = vim.fs.joinpath(data, "dap-adapters")
M.java_debug_dir = vim.fs.joinpath(M.adapter_root, "java-debug")
M.js_debug_dir = vim.fs.joinpath(M.adapter_root, "js-debug")

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
  vim.notify(msg .. "\nRun: bash ~/.config/nvim/scripts/install-dap-adapters.sh", vim.log.levels.WARN)
end

local function setup_signs()
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "DebugLine", numhl = "" })
end

local function setup_python()
  local ok, dap_python = pcall(require, "dap-python")
  if not ok then
    return
  end

  local python = vim.fn.exepath("python3")
  if python == "" then
    python = "python3"
  end

  dap_python.setup(python)

  table.insert(dap_python.configurations.python, {
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

  if vim.fn.isdirectory(M.js_debug_dir) == 0 then
    notify_missing("JS debugger not found at " .. M.js_debug_dir)
    return
  end

  js.setup({
    debugger_path = M.js_debug_dir,
    adapters = { "pwa-node", "pwa-chrome" },
  })

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

  vim.api.nvim_create_user_command("DapInstallAdapters", function()
    vim.notify("Run in a shell:\n  bash ~/.config/nvim/scripts/install-dap-adapters.sh", vim.log.levels.INFO)
  end, { desc = "Show how to install DAP adapters" })

  vim.api.nvim_create_user_command("DapHealth", function()
    local lines = {
      "DAP adapter status:",
      ("  Python (debugpy): %s"):format(vim.fn.executable("python3") == 1 and "python3 on PATH" or "missing python3"),
      ("  Java bundles: %d jar(s) in %s"):format(#M.jdtls_bundles(), M.java_debug_dir),
      ("  JS debugger: %s"):format(
        vim.fn.isdirectory(M.js_debug_dir) == 1 and M.js_debug_dir or "missing (run install script)"
      ),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Check DAP adapter installation" })
end

M.setup()

return M
