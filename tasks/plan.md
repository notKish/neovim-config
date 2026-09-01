# Plan: Full Reorg of Neovim Config

Spec: `../SPEC.md` (approved). Tasks: `tasks/todo.md`. Decisions locked with user.

## Approach

Pure restructure — **zero behavior change**. Move/rename modules into
`lua/core/` + `lua/plugins/` with plain names, split the pack registry from
treesitter config, extract the inline startup screen to `lua/startup.lua`,
delete dead modules (`search.lua`, `fundamentals/`, empty `autocmd/`).

## Implementation order

1. Split registry + treesitter (registry must exist before any plugin config loads)
2. Move core modules (update statusline expr strings + lsp's dap require)
3. Move plugin modules (update codecompanion's ai require + header comments)
4. Rewrite `init.lua` as thin require list; extract startup screen
5. Delete dead code
6. Final verification (load + grep audit + smoke)

## Dependencies (must preserve)

- `plugins` (registry) before `plugins.treesitter` and all other plugin configs
- `core.lsp` before `plugins.snippet` (LspAttach ordering for mini.snippets)
- `plugins.ai` before `plugins.codecompanion` (uses `ai.resolve_config()`)
- `plugins.pick` before `plugins.leetcode` (`:Pick` dependency)
- `plugins.dap` required by `core.lsp` (jdtls bundles) — update the pcall path
- `PackChanged` (TSUpdate) autocmd stays in registry, registered before
  `vim.pack.add` (fresh-install parser behavior)

## New init.lua require order

`plugins` → `plugins.treesitter` → colorscheme → `core.options` →
`core.completion` → `core.highlights` (+ ColorScheme autocmd) → `core.keymaps` →
`core.lsp` → `plugins.dap` → `plugins.snippet` (keep pcall+notify wrapper) →
`plugins.ai` → `plugins.codecompanion` → `core.statusline` → `core.terminal` →
`plugins.pick` → `plugins.leetcode` → `startup`.

## Risks / mitigations

| Risk | Mitigation |
|---|---|
| Statusline/tabline expr strings hardcode module path | Update both `vim.o.statusline` and `vim.o.tabline` in `core/statusline.lua`; verified in smoke |
| `require("plugins")` resolves `lua/plugins/init.lua` | Standard Lua dir-module convention; no `lua/plugins.lua` file exists |
| `PackChanged` autocmd ordering on fresh install | Keep autocmd registration before `vim.pack.add`, in registry |
| Missed `_pack` references | Grep audit after every task (zero hits required) |
| Dead-module comment leftovers in init.lua | Removed in task 4/5; grep audit covers `fundamentals` |

## Verification checkpoints

After each task: headless load (`nvim --headless -c "qa"`, exit 0) + grep audit.
End: full smoke checklist in `tasks/todo.md` task 6.
