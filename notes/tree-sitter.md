# Tree-sitter Integration with Neovim

## Overview

This document describes how tree-sitter parsers are installed and integrated with Neovim 0.11+ using native APIs.

## Parser Sources

### Built-in Parsers

Neovim ships with several tree-sitter parsers pre-compiled:

| Parser | Language |
|--------|----------|
| lua.so | Lua |
| c.so | C |
| markdown.so | Markdown |
| markdown_inline.so | Markdown (inline) |
| query.so | Tree-sitter queries |
| vim.so | Vimscript |
| vimdoc.so | Vim documentation |

Location: `/nix/store/*-neovim-unwrapped-*/lib/nvim/parser/`

### External Parsers (WASM)

Additional parsers are installed as WebAssembly (`.wasm`) files via npm:

| Parser | npm Package |
|--------|-------------|
| python.wasm | tree-sitter-python |
| javascript.wasm | tree-sitter-javascript |
| typescript.wasm | tree-sitter-typescript |
| bash.wasm | tree-sitter-bash |
| json.wasm | tree-sitter-json |
| toml.wasm | tree-sitter-toml |

Location: `~/.local/share/nvim/tree-sitter-parsers/`

## Installation Process

### 1. npm Package Installation

```bash
npm install --prefix ~/.local/share/nvim \
  tree-sitter-python \
  tree-sitter-javascript \
  tree-sitter-typescript \
  tree-sitter-bash \
  tree-sitter-json \
  tree-sitter-toml
```

### 2. CLI Installation (tree-sitter CLI)

```bash
npm install --prefix ~/.local/share/nvim tree-sitter-cli
```

CLI location: `~/.local/share/nvim/node_modules/.bin/tree-sitter`

### 3. WASM Compilation

Each parser grammar npm package contains a `grammar.js` file. The tree-sitter CLI compiles these into `.wasm` files:

```bash
cd ~/.local/share/nvim/node_modules/tree-sitter-python
tree-sitter build --wasm --output ~/.local/share/nvim/tree-sitter-parsers/python.wasm
```

### 4. Parser Directory Structure

```
~/.local/share/nvim/tree-sitter-parsers/
├── bash.wasm
├── javascript.wasm
├── json.wasm
├── lua.wasm       (copied from @tree-sitter-grammars/tree-sitter-lua)
├── python.wasm
├── toml.wasm
└── typescript.wasm
```

## Neovim Integration

### Runtime Path

WASM parsers must be in Neovim's runtimepath:

```lua
vim.opt.runtimepath:append(stdpath("data") .. "/tree-sitter-parsers")
```

### Auto-start on FileType

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "python", "javascript", "typescript", ... },
  callback = function(args)
    local lang = args.match
    -- Start tree-sitter for this buffer
    pcall(vim.treesitter.start, args.buf, lang)
    vim.b[args.buf].ts_active = true
  end,
})
```

### Navigation via Tree-sitter Queries

The integration uses tree-sitter query patterns to find code structure:

```lua
local FUNC_PATTERNS = {
  lua = "((function_declaration) @func)",
  python = "((function_definition) @func)",
  javascript = "((function_declaration) @func)",
  typescript = "((function_declaration) @func)",
  bash = "((function_definition) @func)",
}
```

### Key Mappings

| Mapping | Action |
|---------|--------|
| `[f` / `]f` | Jump to previous/next function |
| `[c` / `]c` | Jump to previous/next class |
| `[{` / `]}` | Jump to previous/next block |
| `[m` / `]m` | Jump to previous/next method |
| `[l` / `]l` | Jump to previous/next loop |
| `[i` / `]i` | Jump to previous/next if/else |
| `gs` | Show symbol under cursor |

## Key APIs Used

### `vim.treesitter.start(buf, lang)`
Starts the tree-sitter highlighter for a buffer.

### `vim.treesitter.get_parser(buf, lang)`
Gets the tree-sitter parser for a buffer and language.

### `vim.treesitter.query.parse(lang, pattern)`
Parses a tree-sitter query pattern.

### `query:iter_captures(root, start_byte)`
Iterates over matches in the syntax tree.

### `TSNode:range()`
Returns `(start_row, start_col, end_row, end_col)` for a node.

### `TSNode:type()`
Returns the node type string (e.g., "function_declaration").

## Troubleshooting

### Check if Parser is Loaded

```lua
:lua print(vim.b.ts_active)
```

### Check Available Languages

```lua
:lua print(vim.inspect(vim.treesitter.language.get_filetypes()))
```

### Manual Parser Installation

If automatic installation fails:

```bash
# Install tree-sitter CLI
npm install --prefix ~/.local/share/nvim tree-sitter-cli

# Build parser as WASM
cd ~/.local/share/nvim/node_modules/tree-sitter-python
~/.local/share/nvim/node_modules/.bin/tree-sitter build --wasm --output ~/.local/share/nvim/tree-sitter-parsers/python.wasm
```

### Check Parser Files

```bash
ls -la ~/.local/share/nvim/tree-sitter-parsers/
```

## Files

- `lua/treesitter.lua` - Main integration module
- Parser directory: `~/.local/share/nvim/tree-sitter-parsers/`
- npm packages: `~/.local/share/nvim/node_modules/tree-sitter-*`