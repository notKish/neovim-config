return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				-- python
				"pyright",
				-- typescript
				"ts_ls",
				"cucumber_language_server",
				"jsonls",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			local on_attach = function(client, bufnr)
				local bufmap = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end

				bufmap("n", "gd", vim.lsp.buf.definition, "[LSP] Go to Definition")
				bufmap("n", "gD", vim.lsp.buf.declaration, "[LSP] Go to Declaration")
				bufmap("n", "gi", vim.lsp.buf.implementation, "[LSP] Go to Implementation")
				bufmap("n", "gr", vim.lsp.buf.references, "[LSP] Go to References")
				bufmap("n", "K", vim.lsp.buf.hover, "[LSP] Hover Documentation")
				bufmap("n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename")
				bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "[LSP] Code Action")
				bufmap("n", "<leader>f", function()
					vim.lsp.buf.format({ async = true })
				end, "[LSP] Format File")
				bufmap("n", "[d", vim.diagnostic.goto_prev, "[LSP] Previous Diagnostic")
				bufmap("n", "]d", vim.diagnostic.goto_next, "[LSP] Next Diagnostic")
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.workspace = capabilities.workspace or {}
			capabilities.workspace.didChangeWorkspaceFolders = {
				dynamicRegistration = true,
			}

			local servers = {
				pyright = {
					settings = {
						python = {
							pythonPath = "/Users/techverito/Apps/python/data-llm-probe/.venv/bin/python",
							analysis = {
								autoSearchPaths = true,
								diagnosticMode = "openFilesOnly",
								useLibraryCodeForTypes = true,
								autoImportCompletions = true,
							},
						},
					},
				},
				lua_ls = {},
				vimls = {},
				ts_ls = {},
				jsonls = {},
				cucumber_language_server = {},
			}

			for server, config in pairs(servers) do
				config.on_attach = on_attach
				config.capabilities = capabilities
				lspconfig[server].setup(config)
			end
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" }, -- load only for Java files
		build = function ()
			vim.cmd("Lazy update nvim-jdtls")
		end
	}
}
