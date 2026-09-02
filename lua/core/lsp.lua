-- Native LSP setup using vim.lsp.config / vim.lsp.enable (Neovim 0.11+)
-- No nvim-lspconfig required.
-- Add servers here as needed; make sure the server binary is on your PATH.

local map = vim.keymap.set
local format_augroup = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })
local document_highlight_augroup = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })
local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
lsp_capabilities.textDocument.completion.completionItem.snippetSupport = true
lsp_capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = { "documentation", "detail", "additionalTextEdits" },
}

local function pyright_add_missing_imports()
  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { "source.addMissingImports.pyright", "quickfix" },
    },
    filter = function(action)
      return action.kind == "source.addMissingImports.pyright"
        or action.title:lower():find("import", 1, true) ~= nil
    end,
  })
end

-- Pum order: (1) LSP semantic; (2) LSP Snippet; (3) LSP Text; (4) buffer/path/tag keywords.
-- Non-LSP items (from 'complete' + <C-n>) have no user_data.nvim.lsp.completion_item.
local kinds = vim.lsp.protocol.CompletionItemKind
local snippet_kind, text_kind = kinds.Snippet, kinds.Text

local function lsp_completion_item(pum_item)
  return vim.tbl_get(pum_item, "user_data", "nvim", "lsp", "completion_item")
end

local function completion_tier(lsp_item)
  if not lsp_item then
    return 4
  end
  local k = lsp_item.kind
  if k == snippet_kind then
    return 2
  end
  if k == text_kind then
    return 3
  end
  return 1
end

local function pum_label(pum_item, lsp_item)
  if lsp_item then
    return lsp_item.sortText or lsp_item.label or ""
  end
  return pum_item.word or pum_item.abbr or ""
end

local function lsp_completion_cmp(a, b)
  local ia = lsp_completion_item(a)
  local ib = lsp_completion_item(b)
  local ta, tb = completion_tier(ia), completion_tier(ib)
  if ta ~= tb then
    return ta < tb
  end
  local fa = a._fuzzy_score or 0
  local fb = b._fuzzy_score or 0
  if fa ~= fb then
    return fa > fb
  end
  return pum_label(a, ia) < pum_label(b, ib)
end

local jdtls_root_markers = {
  ".git",
  "mvnw",
  "gradlew",
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
}

--- Resolve lombok.jar for `-javaagent:` so JDT-LS sees @Data/@Builder generated members.
--- Without this, getters/setters are "undefined" for diagnostics. Override with $JDTLS_LOMBOK_PATH.
local function jdtls_lombok_jar()
  local from_env = vim.env.JDTLS_LOMBOK_PATH
  if type(from_env) == "string" and from_env ~= "" and vim.fn.filereadable(from_env) == 1 then
    return from_env
  end
  local home = vim.env.HOME
  if type(home) ~= "string" or home == "" then
    return nil
  end
  local m2 = vim.fs.joinpath(home, ".m2/repository/org/projectlombok/lombok")
  if vim.fn.isdirectory(m2) == 0 then
    return nil
  end
  local pattern = m2 .. "/*/lombok-*.jar"
  local found = vim.fn.glob(pattern, false, true)
  if type(found) == "string" and found ~= "" then
    found = { found }
  end
  if type(found) ~= "table" or #found == 0 then
    return nil
  end
  table.sort(found)
  return found[#found]
end

local function setup_jdtls_for_buffer(bufnr)
  local ok, jdtls = pcall(require, "jdtls")
  if not ok then
    vim.notify("nvim-jdtls is not installed", vim.log.levels.WARN)
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local root_dir = vim.fs.root(filename, jdtls_root_markers)
  if not root_dir then
    vim.notify("Could not detect Java project root for jdtls", vim.log.levels.WARN)
    return
  end

  local workspace_root = vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls-workspaces")
  vim.fn.mkdir(workspace_root, "p")
  local workspace_dir = vim.fs.joinpath(workspace_root, vim.fs.basename(root_dir))

  local cmd = {
    "jdtls",
    "--jvm-arg=-Xms2G",
    "--jvm-arg=-Xmx4G",
    "--jvm-arg=-XX:+UseG1GC",
    "--jvm-arg=-XX:+UseStringDeduplication",
  }
  local lombok = jdtls_lombok_jar()
  if lombok then
    cmd[#cmd + 1] = "--jvm-arg=-javaagent:" .. lombok
  end
  cmd[#cmd + 1] = "-data"
  cmd[#cmd + 1] = workspace_dir

  jdtls.start_or_attach({
    cmd = cmd,
    root_dir = root_dir,
    capabilities = lsp_capabilities,
    init_options = {
      bundles = (function()
        local ok, dap = pcall(require, "plugins.dap")
        return ok and dap.jdtls_bundles() or {}
      end)(),
    },
    settings = {
      java = {
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
        contentProvider = { preferred = "fernflower" },
        implementationsCodeLens = { enabled = true },
        referencesCodeLens = { enabled = true },
        references = { includeDecompiledSources = true },
        format = { enabled = true },
        imports = {
          gradle = { enabled = true },
          maven = { enabled = true },
        },
        configuration = {
          updateBuildConfiguration = "automatic",
        },
      },
    },
  })
end

-- arduino-language-server: manual per-buffer start like jdtls because the FQBN
-- (board) is per-project and unknown until a sketch is opened. ALS 0.7.7 flags:
-- -clangd -cli [-cli-config] -fqbn (it manages its own temp build dir; it does not
-- read sketch.yaml, so we resolve the FQBN here via plugins.arduino).
local function setup_arduino_for_buffer(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local ok, arduino = pcall(require, "plugins.arduino")
  if not ok then
    return
  end
  local root_dir = arduino.project_root(filename)
  if not root_dir then
    vim.notify("Could not detect Arduino sketch root (no .ino/sketch.yaml/.fqbn)", vim.log.levels.WARN)
    return
  end

  local als = vim.fn.exepath("arduino-language-server")
  local cli = vim.fn.exepath("arduino-cli")
  local clangd = vim.fn.exepath("clangd")
  if als == "" or cli == "" or clangd == "" then
    vim.notify(
      "arduino toolchain missing. Run: darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro",
      vim.log.levels.WARN
    )
    return
  end

  local fqbn = arduino.fqbn(root_dir)
  if not fqbn then
    vim.notify("No FQBN set — use :ArduinoBoard to pick one", vim.log.levels.WARN)
    return
  end

  local cmd = {
    "arduino-language-server",
    "-clangd", clangd,
    "-cli", cli,
    "-fqbn", fqbn,
  }
  local cli_config = vim.fs.joinpath(vim.env.HOME or "", ".arduino15", "arduino-cli.yaml")
  if vim.fn.filereadable(cli_config) == 1 then
    cmd[#cmd + 1] = "-cli-config"
    cmd[#cmd + 1] = cli_config
  end

  vim.lsp.start({
    name = "arduino_language_server",
    cmd = cmd,
    root_dir = root_dir,
    capabilities = lsp_capabilities,
  })
end

-- Language servers often advertise only "." "(" etc. as triggerCharacters. Neovim autotrigger only
-- queries clients registered for the typed key (:h lsp-completion), so without this, "def" only
-- hits mini.snippets — Pyright never runs until <C-Space> (Invoked). Merge identifier chars first.
--
-- Include mini.snippets: |vim.lsp.completion.get()| (e.g. <C-Space>) uses every client in
-- buf_handle.clients, but InsertCharPre autotrigger uses buf_handle.triggers[char] only. If
-- triggerCharacters were empty or dropped when mini attached, mini would still be "enabled" for
-- invoked completion but never run on "d" — exactly "works on C-Space, not on auto trigger".
local function merge_keyword_completion_triggers(client)
  local sc = client.server_capabilities
  if type(sc) ~= "table" then
    return
  end
  -- LSP allows completionProvider: true (shorthand). In Lua `true or {}` is still true, so
  -- triggerCharacters never get merged and |vim.lsp.completion.enable| sees no triggers.
  if type(sc.completionProvider) ~= "table" then
    sc.completionProvider = {}
  end
  local cp = sc.completionProvider
  local tc = cp.triggerCharacters
  if type(tc) ~= "table" then
    tc = {}
    cp.triggerCharacters = tc
  end
  local seen = {}
  for _, ch in ipairs(tc) do
    if type(ch) == "string" and ch ~= "" then
      seen[ch] = true
    end
  end
  local function add(ch)
    if not seen[ch] then
      seen[ch] = true
      tc[#tc + 1] = ch
    end
  end
  for b = string.byte("a"), string.byte("z") do
    add(string.char(b))
  end
  for b = string.byte("A"), string.byte("Z") do
    add(string.char(b))
  end
  for b = string.byte("0"), string.byte("9") do
    add(string.char(b))
  end
  add("_")
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- jdt.ls: publish diagnostics while editing (e.g. constructors); global config has
    -- update_in_insert = false which makes Java errors feel missing until Normal mode.
    if client and client.name == "jdtls" then
      local ns = vim.lsp.diagnostic.get_namespace(client.id)
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = true,
        underline = true,
        update_in_insert = true,
        severity_sort = true,
        float = { border = "rounded", source = true },
      }, ns)
    end

    -- Ruff: prefer Pyright for completion; including Ruff can stall merged completion if its
    -- request never finishes, hiding mini.snippets and other clients.
    if client
      and client.name ~= "ruff"
      and client:supports_method("textDocument/completion")
      and vim.lsp.completion
      and vim.lsp.completion.enable then
      merge_keyword_completion_triggers(client)
      vim.lsp.completion.enable(true, client.id, buf, {
        autotrigger = true,
        cmp = lsp_completion_cmp,
      })
    end

    -- keymaps
    local function bmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    bmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
    bmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    bmap("n", "gr", vim.lsp.buf.references, "References")
    bmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    bmap("n", "gt", vim.lsp.buf.type_definition, "Go to type definition")
    bmap("n", "K", vim.lsp.buf.hover, "Hover docs")
    bmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    bmap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    if client and client.name == "pyright" then
      bmap("n", "<leader>ci", pyright_add_missing_imports, "Add missing imports (Pyright)")
    end
    bmap("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
    bmap("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

    -- highlight references for symbol under cursor
    if client and client:supports_method("textDocument/documentHighlight") then
      vim.api.nvim_clear_autocmds({ group = document_highlight_augroup, buffer = buf })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = document_highlight_augroup,
        buffer = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = document_highlight_augroup,
        buffer = buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- format on save
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = buf })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_augroup,
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({
            bufnr = buf,
            async = false,
            filter = function(c)
              -- Prefer Ruff for Python formatting when available.
              if vim.bo[buf].filetype == "python" then
                return c.name == "ruff"
              end
              return c.id == client.id
            end,
          })
        end,
      })
    end
  end,
})

-- Diagnostic display config
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Server configurations (vim.lsp.config is new in 0.11)
-- Each key matches the server name passed to vim.lsp.enable().

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  capabilities = lsp_capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  capabilities = lsp_capabilities,
})

vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  capabilities = lsp_capabilities,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        indexing = true,
        -- Needed for completions like `Path` -> `from pathlib import Path`
        autoImportCompletions = true,
      },
    },
  },
})

-- Python formatter/imports (ruff server)
vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
})

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
    "--pch-storage=memory",
    "--cross-file-rename",
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  capabilities = lsp_capabilities,
})

vim.lsp.config("bashls", {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash", "zsh" },
  capabilities = lsp_capabilities,
  settings = {
    bashIde = {
      shellcheckPath = "shellcheck",
      globPattern = "*@(.sh|.inc|.bash|.zsh|.command)",
    },
  },
  root_markers = { ".git", "package.json" },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  capabilities = lsp_capabilities,
  settings = {
    gopls = {
      analyses = { unusedparams = true, shadow = true },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.config("nil_ls", {
  cmd = { "nil" },
  filetypes = { "nix" },
  capabilities = lsp_capabilities,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function(args)
    setup_jdtls_for_buffer(args.buf)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "arduino",
  callback = function(args)
    setup_arduino_for_buffer(args.buf)
  end,
})

vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "ruff", "clangd", "bashls", "gopls", "nil_ls" })
