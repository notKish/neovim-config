
	return {
		"nvim-treesitter/nvim-treesitter", 
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local config = require("nvim-treesitter.configs")
			config.setup({
				ensure_installed = {"lua", "javascript", "python", "java"},
				highlight = {enable = true},
				indent = {enable = true}
			})
		end
	}
