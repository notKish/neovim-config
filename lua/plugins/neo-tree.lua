return { {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>e", function()
			vim.cmd("Neotree reveal toggle")
		end, { desc = "Neo-tree (cwd)" })

		vim.keymap.set("n", "<leader>E", function()
			local file_dir = vim.fn.expand("%:p:h") -- full path to file's directory
			vim.cmd("Neotree reveal toggle dir=" .. vim.fn.fnameescape(file_dir))
		end, { desc = "Neo-tree (file dir)" })

		require("neo-tree").setup({
			window = {
				mappings = {
					["l"] = "open",
				},
			},
		})
	end
},
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- Navigate between tabs (buffers)
			vim.keymap.set("n", "<S-L>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
			vim.keymap.set("n", "<S-H>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous tab" })

			require("bufferline").setup({
				options = {
					mode = "buffers",
					numbers = "none",
					show_close_icon = false,
					show_buffer_close_icons = false,
					separator_style = "slant",
					always_show_bufferline = true,
					offsets = {
						{
							filetype = "neo-tree",
							text = "Neo-tree",
							highlight = "Directory",
							text_align = "left",
						},
					},
				},
			})
		end,
	} }
