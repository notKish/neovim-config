-- Native LSP setup using vim.lsp.config / vim.lsp.enable (Neovim 0.11+)
-- No nvim-lspconfig required.
-- Add servers here as needed; make sure the server binary is on your PATH.

local map = vim.keymap.set
local format_augroup = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })
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

local function get_completion_item()
  local completed = vim.v.completed_item or {}
  local user_data = completed.user_data

  -- Native completion metadata shape
  local item = vim.tbl_get(user_data, "nvim", "lsp", "completion_item")
  if item then return item end

  -- Some completion engines encode metadata as JSON in user_data.
  if type(user_data) == "string" and user_data ~= "" then
    local ok, decoded = pcall(vim.json.decode, user_data)
    if ok and type(decoded) == "table" then
      item = vim.tbl_get(decoded, "nvim", "lsp", "completion_item")
        or vim.tbl_get(decoded, "completion_item")
      if item then return item end
    end
  end

  -- Generic fallback if plugin stores the item directly.
  if type(user_data) == "table" then
    return user_data.completion_item
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client and client:supports_method("textDocument/completion")
      and vim.lsp.completion and vim.lsp.completion.enable then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
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
    bmap("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")

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

-- Auto-apply additionalTextEdits (imports) when accepting LSP completion
vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    local item = get_completion_item()
    if not item then return end
    local edits = item.additionalTextEdits
    if edits and #edits > 0 then
      vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), "utf-8")
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
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
})

vim.lsp.config("jdtls", {
  cmd = { "jdtls" },
  filetypes = { "java" },
  settings = {
    java = {
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
      format = { enabled = true },
    },
  },
  root_markers = { "pom.xml", "build.gradle", ".git" },
})

vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "ruff", "clangd", "jdtls" })
