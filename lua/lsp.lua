-- Native LSP setup using vim.lsp.config / vim.lsp.enable (Neovim 0.11+)
-- No nvim-lspconfig required.
-- Add servers here as needed; make sure the server binary is on your PATH.

local map = vim.keymap.set

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- keymaps
    local function bmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    bmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
    bmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    bmap("n", "gr", vim.lsp.buf.references, "References")
    bmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    bmap("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    bmap("n", "K", vim.lsp.buf.hover, "Hover docs")
    bmap("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    bmap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    bmap("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
    bmap("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")

    -- format on save
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = buf, id = client.id, async = false })
        end,
      })
    end

    -- native completion (0.11+)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
      -- trigger completion on every text change in insert mode
      -- vim.api.nvim_create_autocmd("TextChangedI", {
      --   buffer = buf,
      --   callback = function()
      --     vim.lsp.completion.get()
      --   end,
      -- })
    end
  end,
})

-- Auto-apply additionalTextEdits (imports) when accepting LSP completion
vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    local item = vim.tbl_get(vim.v.completed_item, "user_data", "nvim", "lsp", "completion_item")
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
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  },
})

vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
})

vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "clangd" })
