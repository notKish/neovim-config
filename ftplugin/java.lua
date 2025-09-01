local jdtls = require("jdtls")

-- Find project root
local root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })

-- Location of jdtls and java-debug
local home = os.getenv("HOME")
local jdtls_path = home .. "/.local/share/nvim/mason/packages/jdtls"
local java_debug_path = home .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/"

local bundles = {
	vim.fn.glob(java_debug_path .. "com.microsoft.java.debug.plugin-*.jar", 1)
}

local config = {
	cmd = {
		"java", -- or full path to java
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xms1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens", "java.base/java.util=ALL-UNNAMED",
		"--add-opens", "java.base/java.lang=ALL-UNNAMED",
		"-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
		"-configuration", jdtls_path .. "/config_mac", -- or config_linux / config_win
		"-data", home .. "/workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t"),
	},

	root_dir = root_dir,

	init_options = {
		bundles = bundles,
	},

	settings = {
		java = {
			home = home .. "/Library/Java/JavaVirtualMachines/temurin-17.0.13/Contents/Home/",
		},
	},
}

-- Setup debugging
jdtls.start_or_attach(config)
jdtls.setup_dap({ hotcodereplace = "auto" })
-- jdtls.setup_dap_main_class_configs()

-- helper wrapper
local function map(mode, lhs, rhs, opts)
  local options = { buffer = true, silent = true }
  if type(opts) == "string" then
    options.desc = opts
  elseif type(opts) == "table" then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Keymaps for Java
map("n", "<leader>oi", jdtls.organize_imports, { desc = "Organize Imports" })
map("n", "<leader>ev", jdtls.extract_variable, { desc = "Extract Variable" })
map("n", "<leader>ec", jdtls.extract_constant, { desc = "Extract Constant" })
map("v", "<leader>em",
  [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
  { desc = "Extract Method" }
)

map("n", "gd", vim.lsp.buf.definition, "[LSP] Go to Definition")
map("n", "gD", vim.lsp.buf.declaration, "[LSP] Go to Declaration")
map("n", "gi", vim.lsp.buf.implementation, "[LSP] Go to Implementation")
map("n", "gr", vim.lsp.buf.references, "[LSP] Go to References")
map("n", "K", vim.lsp.buf.hover, "[LSP] Hover Documentation")
map("n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename")
map("n", "<leader>ca", vim.lsp.buf.code_action, "[LSP] Code Action")
map("n", "<leader>f", function()
  vim.lsp.buf.format({ async = true })
end, "[LSP] Format File")
map("n", "[d", vim.diagnostic.goto_prev, "[LSP] Previous Diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "[LSP] Next Diagnostic")
