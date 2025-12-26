-- Plugin configuration for LazyVim
-- This file contains custom plugin configurations and overrides

return {
	-- ============================================================================
	-- LazyVim Extras
	-- ============================================================================
	{ import = "lazyvim.plugins.extras.lang.typescript" },
	{ import = "lazyvim.plugins.extras.lang.json" },
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
		opts = {
			servers = {
				-- Nix LSP for .nix and .flake files
				nil_ls = {},
				-- Java LSP
				jdtls = {},
				-- Other LSPs will be auto-detected from PATH
			},
		},
	},

	-- ============================================================================
	-- TypeScript
	-- ============================================================================
	{
		"jose-elias-alvarez/typescript.nvim",
		keys = {
			{ "<leader>co", "<cmd>TypescriptOrganizeImports<cr>", desc = "Organize Imports" },
			{ "<leader>cR", "<cmd>TypescriptRenameFile<cr>", desc = "Rename File" },
		},
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
