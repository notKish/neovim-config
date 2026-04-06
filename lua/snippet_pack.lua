-- mini.snippets + friendly-snippets (vim.pack). Load after lua/lsp.lua so LspAttach runs when this attaches.
-- Autotrigger only fires for LSP triggerCharacters; mini defaults to {} so we register alnum (|:h lsp-completion|).
local mini_snippets = require("mini.snippets")

local function snippet_trigger_chars()
  local t = {}
  for b = string.byte("a"), string.byte("z") do
    t[#t + 1] = string.char(b)
  end
  for b = string.byte("A"), string.byte("Z") do
    t[#t + 1] = string.char(b)
  end
  for b = string.byte("0"), string.byte("9") do
    t[#t + 1] = string.char(b)
  end
  t[#t + 1] = "_"
  return t
end
local gen_loader = mini_snippets.gen_loader

local lang_patterns = {
  javascriptreact = { "javascript/**/*.json", "javascript/**/*.lua", "**/javascript.json", "**/javascript.lua" },
  typescriptreact = { "typescript/**/*.json", "typescript/**/*.lua", "**/typescript.json", "**/typescript.lua" },
  jsonc = { "json/**/*.json", "json/**/*.lua", "**/json.json", "**/json.lua" },
  sh = { "bash/**/*.json", "bash/**/*.lua", "**/bash.json", "**/bash.lua" },
}

mini_snippets.setup({
  snippets = {
    gen_loader.from_lang({ lang_patterns = lang_patterns }),
  },
  mappings = {
    expand = "",
    jump_next = "",
    jump_prev = "",
    stop = "",
  },
  expand = {
    insert = function(snippet, _)
      vim.snippet.expand(snippet.body)
    end,
  },
})

-- match = false: fuzzy filter in the UI; triggers = alnum so InsertCharPre includes this client with autotrigger.
mini_snippets.start_lsp_server({
  match = false,
  triggers = snippet_trigger_chars(),
})
