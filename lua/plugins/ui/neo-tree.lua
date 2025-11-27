return { {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	config = function()
		-- Open Neo-tree with CWD (terminal’s current directory)
		vim.keymap.set("n", "<leader>e", function()
			local cwd = vim.fn.getcwd()
			vim.cmd("Neotree reveal toggle dir=" .. vim.fn.fnameescape(cwd))
		end, { desc = "Neo-tree (cwd)" })

		-- Open Neo-tree in current file’s directory
		vim.keymap.set("n", "<leader>E", function()
			local file_dir = vim.fn.expand("%:p:h")
			vim.cmd("Neotree reveal toggle dir=" .. vim.fn.fnameescape(file_dir))
		end, { desc = "Neo-tree (file dir)" })

		-- Open Neo-tree for Neovim config lua folder
		vim.keymap.set("n", "<leader>lc", function()
			vim.cmd("Neotree reveal dir=~/.config/nvim/lua")
		end, { desc = "Neo-tree: open nvim lua config" })

		require("neo-tree").setup({
			hide_dotfiles = false,
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
