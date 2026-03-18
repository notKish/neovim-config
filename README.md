# Neovim config — minimal

Zero-distro config. No LazyVim, no opinionated extras — just the plugins actually needed.

## Requirements

- Neovim 0.11+
- `git`, `ripgrep`, `fd`
- LSP servers on PATH (install via Mason or system package manager):
  `lua-language-server`, `pyright`, `ruff`, `typescript-language-server`,
  `gopls`, `clangd`, `jdtls`, `bash-language-server`
- Optional: `fzf` (speeds up fzf-lua)

## Structure

```
init.lua              — entry point, sources core/* and plugins/
lua/
  core/
    options.lua       — vim.opt settings
    keymaps.lua       — all key mappings
    autocmds.lua      — autocommands
    statusline.lua    — hand-rolled statusline
    terminal.lua      — floating terminal toggle
    lsp.lua           — vim.lsp.enable() + LspAttach keymaps
  plugins/
    init.lua          — lazy.nvim bootstrap + all plugin specs
lsp/
  <server>.lua        — per-server LSP config files
```

## Plugins

| Plugin | Purpose |
|---|---|
| tokyonight.nvim | Colorscheme |
| nvim-treesitter | Syntax, indent, folding |
| fzf-lua | Files, grep, buffers, LSP symbols |
| blink.cmp | Completion |
| gitsigns.nvim | Git hunk signs + blame |
| mini.pairs | Auto pairs |
| mini.surround | Surround operations |
| mini.comment | `gc` to comment |

## Key mappings

`<leader>` = `Space`

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fr` | Recent files |
| `<leader>fs` | LSP document symbols |
| `<leader>fd` | Document diagnostics |
| `<leader>t` | Toggle floating terminal |
| `<leader>fm` | Format file (LSP) |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover docs |
