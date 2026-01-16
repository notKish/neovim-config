-- Plugin configuration for LazyVim
-- This file contains custom plugin configurations and overrides

return {
	-- ============================================================================
	-- LazyVim Extras
	-- ============================================================================
	{ import = "lazyvim.plugins.extras.lang.typescript" },
	{ import = "lazyvim.plugins.extras.lang.json" },
	{ import = "lazyvim.plugins.extras.lang.python" },
	{ import = "lazyvim.plugins.extras.ai.avante" },
	-- NOTE: DAP core requires Mason, so we skip it when using Nix

	-- ============================================================================
	-- AI Integration
	-- ============================================================================
	{
		"yetone/avante.nvim",
		opts = {
			provider = "openai",
			providers = {
				openai = {
					endpoint = "https://api.openai.com/v1",
					model = "gpt-4o",
					timeout = 30000,
					extra_request_body = { temperature = 0.7, max_tokens = 4096 },
				},
				anthropic = {
					endpoint = "https://api.anthropic.com/v1",
					model = "claude-3-5-sonnet-20241022",
					timeout = 30000,
					extra_request_body = { temperature = 0.7, max_tokens = 4096 },
				},
			},
			behaviour = { auto_set_keymaps = true },
		},
	},

	-- ============================================================================
	-- Mason Disable (using Nix instead)
	-- ============================================================================
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{ "mason-org/mason-nvim-dap.nvim", enabled = false },

	-- ============================================================================
	-- LSP Configuration (Nix-provided servers)
	-- ============================================================================
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- Ensure servers table exists
			opts.servers = opts.servers or {}
			
			-- Merge/override specific server configurations
			-- Nix LSP for .nix and .flake files
			opts.servers.nil_ls = opts.servers.nil_ls or {}
			
			-- Java LSP
			opts.servers.jdtls = opts.servers.jdtls or {}
			
			-- Python LSP - pyright provides type checking, code completion, go-to-definition
			opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
				settings = {
					pyright = {
						-- Use project-specific Python interpreter
						useLibraryCodeForTypes = true,
					},
					python = {
						analysis = {
							autoImportCompletions = true,
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							typeCheckingMode = "basic",
							useLibraryCodeForTypes = true,
						},
					},
				},
			})
			
			-- Ruff LSP server (provides linting, formatting, and quick fixes)
			-- Works alongside pyright - pyright handles type checking/completion, ruff handles linting/formatting
			opts.servers.ruff = opts.servers.ruff or {}
			
			-- Don't override vtsls - let TypeScript extra configure it
			-- opts.servers.vtsls is handled by TypeScript extra
			
			return opts
		end,
	},

	-- ============================================================================
	-- TypeScript
	-- ============================================================================
	-- {
	-- 	"jose-elias-alvarez/typescript.nvim",
	-- 	keys = {
	-- 		{ "<leader>co", "<cmd>TypescriptOrganizeImports<cr>", desc = "Organize Imports" },
	-- 		{ "<leader>cR", "<cmd>TypescriptRenameFile<cr>", desc = "Rename File" },
	-- 	},
	-- },

	-- ============================================================================
	-- Python: Ruff Formatter & Linter (not provided by Python extras)
	-- ============================================================================
	-- Python extras provide pyright LSP and venv-selector, but not ruff formatter/linter
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
			return opts
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			opts.linters = opts.linters or {}
			opts.linters.ruff = {
				cmd = "ruff",
				args = { "check", "--output-format", "text", "--stdin-filename", "$FILENAME", "-" },
				stdin = true,
			}
			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.python = { "ruff" }
			return opts
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
