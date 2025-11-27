return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP source
			"hrsh7th/cmp-buffer", -- Buffer source
			"hrsh7th/cmp-path",  -- Path (filesystem) source
			"milanglacier/minuet-ai.nvim"
		},
		config = function()
			local cmp = require("cmp")

			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = require("minuet").make_cmp_map(),
					-- ["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = cmp.config.sources(
					{name = "minuet"},
					{
						{ name = "nvim_lsp" }, -- LSP completions
						{ name = "path" }, -- File path completions
					},
					{
						{ name = "buffer" }, -- Buffer words (lower priority)
					}),
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
			})
		end,
	}
}
