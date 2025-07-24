return {
	{
		"mason-org/mason.nvim",
		opts = {}
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = { "pyright", "ts_ls", "cucumber_language_server" },
			automatic_enable = true
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")

			-- LSP keybindings
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

				-- Signature help (now handled by nvim-cmp)
				-- vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "[LSP] Signature Help" })

			end
			-- cmp capabilities
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Setup each server
			lspconfig.pyright.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					python = {
						pythonPath = "/Users/techverito/Apps/python/data-llm-probe/.venv/bin/python", -- ✅ your actual interpreter
						analysis = {
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							useLibraryCodeForTypes = true,
							autoImportCompletions = true
						},
					}
				}
			})
			lspconfig.lua_ls.setup({ on_attach = on_attach, capabilities = capabilities })
			lspconfig.vimls.setup({ on_attach = on_attach, capabilities = capabilities })
			lspconfig.ts_ls.setup({ on_attach = on_attach, capabilities = capabilities })
			lspconfig.cucumber_language_server.setup({ on_attach = on_attach, capabilities = capabilities })
		end
	},
	}
