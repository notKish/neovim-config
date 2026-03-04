-- Plugin configuration for LazyVim
-- This file contains custom plugin configurations and overrides

return {
	-- ============================================================================
	-- LazyVim Extras
	-- ============================================================================
	{ import = "lazyvim.plugins.extras.dap.core" }, -- DAP core (must be before lang.python)
	{ import = "lazyvim.plugins.extras.lang.typescript" },
	{ import = "lazyvim.plugins.extras.lang.json" },
	{ import = "lazyvim.plugins.extras.lang.python" },
	{ import = "lazyvim.plugins.extras.lang.go" },
	{ import = "lazyvim.plugins.extras.lang.clangd" },
	{ import = "lazyvim.plugins.extras.ui.treesitter-context" }, -- Sticky function headers when scrolling
	{ import = "lazyvim.plugins.extras.util.project" }, -- Recent projects picker (<leader>fp)

	-- ============================================================================
	-- Workspaces — named multi-root workspaces, switch between projects anywhere on disk
	-- ============================================================================
	{
		"natecraddock/workspaces.nvim",
		cmd = { "WorkspacesAdd", "WorkspacesOpen", "WorkspacesRemove", "WorkspacesList" },
		opts = {
			-- save session automatically when switching workspaces
			hooks = {
				open_pre = { "SessionStop" },
				open = { "SessionLoad" },
			},
		},
		keys = {
			{ "<leader>fw", "<cmd>WorkspacesOpen<cr>", desc = "Open Workspace" },
			{ "<leader>fW", "<cmd>WorkspacesAdd<cr>", desc = "Add Workspace" },
		},
	},

	-- ============================================================================
	-- CodeCompanion — AI chat + inline assistant (DeepSeek via OpenAI-compatible API)
	-- ============================================================================
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			adapters = {
				deepseek = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						name = "deepseek",
						env = {
							url = "https://api.deepseek.com",
							api_key = "DEEPSEEK_API_KEY",
						},
						schema = {
							model = {
								default = "deepseek-chat",
							},
						},
					})
				end,
			},
			strategies = {
				chat = { adapter = "deepseek" },
				inline = { adapter = "deepseek" },
				agent = { adapter = "deepseek" },
			},
		},
		keys = {
			{ "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "CodeCompanion Chat" },
			{ "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions", mode = { "n", "v" } },
			{ "<leader>ai", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion Inline", mode = { "n", "v" } },
		},
	},

	-- ============================================================================
	-- Minuet AI — ghost text + completion (DeepSeek, configurable providers)
	-- ============================================================================
	{
		"milanglacier/minuet-ai.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- provider options: openai_fim_compatible, openai
			provider = "openai_fim_compatible",
			request_timeout = 4,
			throttle = 1200,
			debounce = 500,
			n_completions = 3,
			context_window = 8000,
			provider_options = {
				openai_fim_compatible = {
					api_key = "DEEPSEEK_API_KEY",
					name = "deepseek",
					end_point = "https://api.deepseek.com/beta/completions",
					model = "deepseek-chat",
					optional = {
						max_tokens = 256,
						top_p = 0.9,
						stop = { "\n\n" },
					},
				},
				openai = {
					api_key = "OPENAI_API_KEY",
					model = "gpt-4o-mini",
					end_point = "https://api.openai.com/v1/chat/completions",
					optional = {
						max_tokens = 256,
						top_p = 0.9,
					},
				},
			},
			-- Virtual text (ghost text): separate keymaps so Tab stays for completion-list cycle
			virtualtext = {
				auto_trigger_ft = { "python", "lua", "typescript", "javascript", "nix", "rust", "go", "c", "cpp" },
				keymap = {
					-- C-y and M-CR often conflict with blink / don't work in Ghostty; use these instead
					accept = "<C-CR>", -- accept whole ghost (Ctrl+Enter)
					accept_line = "<S-CR>", -- accept one line of ghost (Shift+Enter)
					next = "<C-j>",
					prev = "<C-k>",
					dismiss = "<C-e>",
				},
			},
		},
	},
	-- Wire Minuet into blink.cmp (LazyVim default) so you can cycle in the completion menu too
	{
		"Saghen/blink.cmp",
		optional = true,
		opts = function(_, opts)
			opts.keymap = opts.keymap or {}
			-- Tab: open completion menu and cycle (insert_next triggers completion if menu not visible)
			opts.keymap["<Tab>"] = { "insert_next", "snippet_forward", "fallback" }
			opts.keymap["<S-Tab>"] = { "insert_prev", "snippet_backward", "fallback" }
			-- C-Space: use default (show full completion list); don't override to Minuet-only
			opts.sources = opts.sources or {}
			opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
			if not vim.tbl_contains(opts.sources.default, "minuet") then
				table.insert(opts.sources.default, "minuet") -- at end so Minuet appears after LSP/path/snippets/buffer
			end
			opts.sources.providers = opts.sources.providers or {}
			opts.sources.providers.minuet = {
				name = "minuet",
				module = "minuet.blink",
				async = true,
				timeout_ms = 4000,
				score_offset = -50, -- lower score so Minuet suggestions tend to appear at end of list
			}
			opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
				trigger = { prefetch_on_insert = false },
			})
		end,
	},

	-- ============================================================================
	-- Mason disabled — language tools are provided on PATH (e.g. by Nix / system).
	-- ============================================================================
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{ "mason-org/mason-nvim-dap.nvim", enabled = false },

	-- ============================================================================
	-- LSP server overrides
	-- ============================================================================
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- Ensure servers table exists
			opts.servers = opts.servers or {}

			-- Merge/override specific server configurations
			opts.servers.nil_ls = opts.servers.nil_ls or {}

			-- Java LSP (Nix: jdt-language-server). Lombok via LOMBOK_JAR so @Data/@AllArgsConstructor are understood.
			opts.servers.jdtls = opts.servers.jdtls or {}
			do
				local lombok_jar = vim.env.LOMBOK_JAR
				if lombok_jar and lombok_jar ~= "" and vim.fn.filereadable(lombok_jar) == 1 then
					opts.servers.jdtls.cmd = { "jdtls", string.format("--jvm-arg=-javaagent:%s", lombok_jar) }
				end
			end

			-- Python LSP
			-- Optimized for performance to reduce lag
			-- Merge with LazyVim's Python extras pyright config
			opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
				settings = {
					pyright = {
						-- Use project-specific Python interpreter
						useLibraryCodeForTypes = false, -- Disabled for performance (can cause lag)
					},
					python = {
						analysis = {
							-- Performance optimizations
							autoImportCompletions = true,
							autoSearchPaths = false, -- Disabled for performance (reduces scanning)
							diagnosticMode = "openFilesOnly", -- Only check open files
							typeCheckingMode = "basic", -- Can be set to "off" if still laggy
							useLibraryCodeForTypes = false, -- Disabled for performance (can cause significant lag)
							-- Exclude patterns to reduce scanning scope
							exclude = {
								"**/node_modules",
								"**/__pycache__",
								"**/.*",
								"**/venv",
								"**/.venv",
								"**/env",
								"**/.env",
								"**/build",
								"**/dist",
								"**/.git",
							},
						},
					},
				},
			})

			-- Ruff LSP server (provides linting, formatting, and quick fixes)
			-- Works alongside pyright - pyright handles type checking/completion, ruff handles linting/formatting
			opts.servers.ruff = opts.servers.ruff or {}

			-- TypeScript LSP - vtsls optimized for performance
			opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
				settings = {
					typescript = {
						-- Performance optimizations
						preferences = {
							includePackageJsonAutoImports = "off", -- Disable auto-imports from package.json (can be slow)
							disableSuggestions = false,
						},
						inlayHints = {
							-- Disable inlay hints if causing lag
							parameterNames = { enabled = "none" },
							variableTypes = { enabled = false },
							propertyDeclarationTypes = { enabled = false },
							functionLikeReturnTypes = { enabled = false },
						},
						-- Limit workspace scanning
						maxTsServerMemory = 4096, -- Limit memory usage (MB)
					},
				javascript = {
					preferences = {
						includePackageJsonAutoImports = "off",
						disableSuggestions = false,
					},
					inlayHints = {
						parameterNames = { enabled = "none" },
						variableTypes = { enabled = false },
						propertyDeclarationTypes = { enabled = false },
						functionLikeReturnTypes = { enabled = false },
					},
				},
				-- maxTsServerMemory is a root-level vtsls setting (not per-language)
				vtsls = {
					maxTsServerMemory = 4096,
				},
				},
			})

			return opts
		end,
	},

	-- ============================================================================
	-- Formatters (conform.nvim)
	-- ============================================================================
	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			opts.formatters = opts.formatters or {}
			opts.formatters.ruff_format = {
				command = "ruff",
				args = { "format", "--stdin-filename", "$FILENAME", "-" },
				stdin = true,
			}
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.python = { "ruff_format" }
			opts.formatters_by_ft.go = { "gofumpt" }
			opts.formatters.clang_format = {
				command = "clang-format",
				args = { "--style=file", "--assume-filename", "$FILENAME", "-" },
				stdin = true,
			}
			opts.formatters_by_ft.c = { "clang_format" }
			opts.formatters_by_ft.cpp = { "clang_format" }
			-- prettierd (faster prettier daemon) for web filetypes
			opts.formatters_by_ft.javascript = { "prettierd" }
			opts.formatters_by_ft.javascriptreact = { "prettierd" }
			opts.formatters_by_ft.typescript = { "prettierd" }
			opts.formatters_by_ft.typescriptreact = { "prettierd" }
			opts.formatters_by_ft.json = { "prettierd" }
			opts.formatters_by_ft.html = { "prettierd" }
			opts.formatters_by_ft.css = { "prettierd" }
			opts.formatters_by_ft.markdown = { "prettierd" }
			return opts
		end,
	},

	-- ============================================================================
	-- Python DAP Configuration (without Mason)
	-- ============================================================================
	-- Configure nvim-dap-python to use system Python or venv debugpy
	-- Note: Install debugpy with: pip install debugpy (or in your venv)
	{
		"mfussenegger/nvim-dap-python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			-- Resolve Python: venv > .venv > python3 on PATH (with debugpy) > fallback
			local python_path = function()
				-- Check for virtual environment (project-specific, most common)
				local venv = vim.fn.expand("$VIRTUAL_ENV")
				if venv ~= "" and venv ~= vim.NIL then
					local venv_python = venv .. "/bin/python"
					if vim.fn.executable(venv_python) == 1 then
						return venv_python
					end
				end
				-- Check for .venv in current directory
				local cwd = vim.fn.getcwd()
				local local_venv = cwd .. "/.venv/bin/python"
				if vim.fn.executable(local_venv) == 1 then
					return local_venv
				end
				local path_python = vim.fn.exepath("python3")
				if path_python ~= "" then
					local ok = vim.fn.system("python3 -c 'import debugpy' 2>&1")
					if vim.v.shell_error == 0 then
						return path_python
					end
				end
				-- Fall back to system Python
				return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python3"
			end

			local path = python_path()
			require("dap-python").setup(path)

			-- Set test runner
			require("dap-python").test_runner = "pytest"

			-- Custom DAP configurations for Python
			local dap = require("dap")

			-- Configuration: Python File (default - runs current file)
			dap.configurations.python = dap.configurations.python or {}
			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "Python: Current File",
				program = "${file}",
				console = "integratedTerminal",
				justMyCode = true,
			})

			-- Configuration: Python File with Arguments (prompts for args)
			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "Python: File with Args",
				program = "${file}",
				args = function()
					local args_string = vim.fn.input("Arguments (space-separated): ")
					return vim.split(args_string, " +")
				end,
				console = "integratedTerminal",
				justMyCode = true,
			})

			-- Configuration: Python Module (e.g., python -m pytest)
			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "Python: Module",
				module = function()
					return vim.fn.input("Module to run (e.g., pytest): ")
				end,
				console = "integratedTerminal",
				justMyCode = true,
			})

			-- Configuration: Attach to Running Process
			table.insert(dap.configurations.python, {
				type = "python",
				request = "attach",
				name = "Python: Attach",
				connect = {
					host = function()
						return vim.fn.input("Host [localhost]: ", "localhost")
					end,
					port = function()
						return tonumber(vim.fn.input("Port [5678]: ", "5678"))
					end,
				},
				justMyCode = true,
			})

			-- Configuration: Pytest (for debugging tests)
			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "Python: Pytest",
				module = "pytest",
				args = {
					"${file}",
					"-v",
				},
				console = "integratedTerminal",
				justMyCode = false, -- Include library code for test debugging
			})

			-- Optional: Customize breakpoint appearance
			vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "🟡", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
			)
			vim.fn.sign_define("DapLogPoint", { text = "🔵", texthl = "DapLogPoint", linehl = "", numhl = "" })
		end,
	},

	-- ============================================================================
	-- Treesitter
	-- ============================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, {
				"bash",
				"c",
				"cpp",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"tsx",
				"typescript",
				"vim",
				"yaml",
				"nix", -- for .flake files
				"java",
			})
		end,
	},
}
