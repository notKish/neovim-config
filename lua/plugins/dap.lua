return {
	-- DAP (Debug Adapter Protocol)
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"jay-babu/mason-nvim-dap.nvim",
			"nvim-neotest/nvim-nio", -- Required by some DAP UIs
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({}) -- Use default UI layout

			-- Define DAP signs and highlights
			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
			vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#993939" })
			vim.api.nvim_set_hl(0, "DapStopped", { fg = "#779977" })
			vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2d2d2d" })

			-- DAP UI listeners to open/close UI automatically
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Close Neo-tree when DAP UI opens
			vim.api.nvim_create_autocmd("User", {
				pattern = "DapUIOpen",
				callback = function()
					vim.cmd("Neotree close")
				end,
				desc = "Close Neo-tree when DAP UI opens",
			})


			-- Explicitly define the pwa-node adapter for nvim-dap
			dap.adapters["pwa-node"] = {
				type = 'server',
				host = '::1',
				port = '${port}',
				executable = {
					command = 'js-debug-adapter',
					args = {
						'${port}',
					},
				},
			}

			-- Configure TypeScript debugging
			dap.configurations.typescript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug current TS file",
					program = "${file}",
					cwd = "${workspaceFolder}",
					runtimeExecutable = "node",
					runtimeArgs = { "--loader", "ts-node/esm" },
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug Playwright Test (TS)",
					program = "${workspaceFolder}/node_modules/.bin/playwright",
					args = { "test", "${file}", "--debug" },
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to process ID (TS)",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
			}

			-- Configure JavaScript debugging
			dap.configurations.javascript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug current JS file",
					program = "${file}",
					cwd = "${workspaceFolder}",
					runtimeExecutable = "node",
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug Playwright Test (JS)",
					program = "${workspaceFolder}/node_modules/.bin/playwright",
					args = { "test", "${file}", "--debug" },
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to process ID (JS)",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					protocol = "inspector",
					skipFiles = { "<node_internals>/**", "**/node_modules/**" },
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
				},
			}

			-- Keybindings for debugging
			vim.keymap.set("n", "<F5>", function()
				dap.continue()
			end, { desc = "DAP: Continue / Run" })
			vim.keymap.set("n", "<F10>", function() dap.step_over() end, { desc = "DAP: Step Over" })
			vim.keymap.set("n", "<F11>", function() dap.step_into() end, { desc = "DAP: Step Into" })
			vim.keymap.set("n", "<F12>", function() dap.step_out() end, { desc = "DAP: Step Out" })
			vim.keymap.set("n", "<leader>b", function() dap.toggle_breakpoint() end, { desc = "DAP: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
				{ desc = "DAP: Set Conditional Breakpoint" })
			vim.keymap.set("n", "<leader>du", function() dapui.toggle() end, { desc = "DAP UI: Toggle" })
			vim.keymap.set("n", "<leader>de", function() dapui.eval() end, { desc = "DAP UI: Evaluate Expression" })
			vim.keymap.set("n", "<leader>dr", function() dapui.repl() end, { desc = "DAP UI: Open REPL" })
		end,
	},
}
