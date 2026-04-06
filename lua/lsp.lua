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

-- Sort Snippet (mini.snippets / friendly-snippets) before other LSP kinds so short prefixes like "d"
-- still show `def` etc. near the top of the pum. Only the first |vim.lsp.completion.enable| for a
-- buffer stores `cmp`, so pass this from every client — whichever attaches first wins.
local snippet_kind = vim.lsp.protocol.CompletionItemKind.Snippet
local function lsp_completion_cmp(a, b)
  local ia = vim.tbl_get(a, "user_data", "nvim", "lsp", "completion_item")
  local ib = vim.tbl_get(b, "user_data", "nvim", "lsp", "completion_item")
  local ka, kb = ia and ia.kind, ib and ib.kind
  if ka == snippet_kind and kb ~= snippet_kind then
    return true
  end
  if kb == snippet_kind and ka ~= snippet_kind then
    return false
  end
  local la = ia and (ia.sortText or ia.label) or ""
  local lb = ib and (ib.sortText or ib.label) or ""
  return la < lb
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
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  capabilities = lsp_capabilities,
})

vim.lsp.config("jdtls", {
  cmd = { "jdtls" },
  filetypes = { "java" },
  capabilities = lsp_capabilities,
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
