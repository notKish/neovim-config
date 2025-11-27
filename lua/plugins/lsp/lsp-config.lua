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

			local on_attach = function(client, bufnr)
				-- Debug: print when LSP attaches
				print("LSP attached:", client.name, "to buffer", bufnr)

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
				lua_ls = {
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
							},
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = {
								enable = false,
							},
						},
					},
				},
				vimls = {},
				jsonls = {
					settings = {
						json = {
							validate = { enable = true },
							format = {
								enable = true,
							},
						},
				},
				cucumber_language_server = {},
			}
			}

			-- Setup ts_ls with error handling to fix the Neo-tree error
			local function setup_ts_ls()
				local util = require("lspconfig.util")

				vim.lsp.config.ts_ls.setup({
					on_attach = on_attach,
					capabilities = capabilities,
					-- Fix the root_dir issue that was causing the error
					root_dir = function(fname)
						return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json")(fname)
								or util.root_pattern(".git")(fname)
					end,
					settings = {
						typescript = {
							preferences = {
								disableSuggestions = true,
							},
						},
						javascript = {
							preferences = {
								disableSuggestions = true,
							},
						},
					},
				})
			end

			-- Setup other servers
			for server, config in pairs(servers) do
				config.on_attach = on_attach
				config.capabilities = capabilities
				require("lspconfig")[server].setup(config)
			end

			-- Setup ts_ls with error handling
			local ok, err = pcall(setup_ts_ls)
			if not ok then
				vim.notify("Failed to setup ts_ls: " .. tostring(err), vim.log.levels.WARN)
				-- Fallback: setup with minimal config
				pcall(function()
					vim.lsp.config.ts_ls.setup({
						on_attach = on_attach,
						capabilities = capabilities,
					})
				end)
			end
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" }, -- load only for Java files
		build = function()
			vim.cmd("Lazy update nvim-jdtls")
		end
	}
}
