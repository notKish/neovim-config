return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				-- null_ls.builtins.formatting.stylua
			}
		})
		vim.lsp.buf.code_action({
			-- Keymaps
			vim.keymap.set("v", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
		})
	end
}
