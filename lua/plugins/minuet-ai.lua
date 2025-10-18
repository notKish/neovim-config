return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
	},
	config = function()
		require("minuet").setup({
			provider = "gemini", -- or "openai", "claude", etc.
			frontend = "nvim-cmp", 
			provider_options = {
				gemini = {
					model = "gemini-2.0-flash",
					api_key = "GEMINI_API_KEY",
					stream = true,
					end_point = "https://generativelanguage.googleapis.com/v1beta/models",
					optional = {
						generationConfig = {
							maxOutputTokens = 256,
						},
						safetySettings = {
							{
								category = "HARM_CATEGORY_DANGEROUS_CONTENT",
								threshold = "BLOCK_ONLY_HIGH",
							},
						},
					},
				},
			},
			notify = 'debug'
		})
	end

}
