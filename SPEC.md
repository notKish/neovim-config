# Spec: Full Reorg of Neovim Config (naming, layout, require order)

## Objective

Restructure `/Users/ganesh/.config/nvim` from a flat, inconsistently-named `lua/`
tree (mixed plain names, `*_pack.lua` suffix, kebab-case `pack-plugins.lua`) into
a consistent `core/` + `plugins/` layout with plain module names, extract the
inline startup screen out of `init.lua`, and remove dead/suspended modules.

**Zero behavior change** — same keymaps, options, colorscheme, and plugin
configs; only file paths, require strings, and comments move.

Per spec-driven-development Phase 0: this is a single capability (consistent
config layout), so no capability map is needed.

## Decisions (locked with user)

| Decision | Choice |
|---|---|
| Structure | `lua/core/` (editor behavior) + `lua/plugins/` (third-party integrations) + `lua/startup.lua` |
| Naming | Plain names everywhere; drop `_pack` suffix and kebab `pack-` |
| Dead code | Delete `lua/search.lua`, `lua/fundamentals/`, empty `lua/autocmd/` |
| Startup screen | Extract inline `VimEnter` block from `init.lua` → `lua/startup.lua` |
| Registry | Split `pack-plugins.lua` → `lua/plugins/init.lua` (registry) + `lua/plugins/treesitter.lua` (treesitter config) |

## Tech Stack

Neovim 0.12+ (`vim.pack`, `vim.lsp.config`), LuaJIT. No new dependencies.

## Commands

```
Load check:   nvim --headless -c "qa"          # exit 0, no error output
Grep audit:   grep -rn "dap_pack\|pick_pack\|snippet_pack\|codecompanion_pack\|leetcode_pack\|pack-plugins\|require(\"search\")\|require(\"fundamentals\")\|require('statusline')" --include="*.lua" .
Smoke:        nvim  (manual checklist in tasks/todo.md)
```

## Project Structure

```
init.lua                → thin ordered require list (colorscheme + ColorScheme autocmd stay here)
lua/
  core/                 → editor behavior (no third-party deps)
    options.lua         ← from options.lua
    keymaps.lua         ← from keymaps.lua
    lsp.lua             ← from lsp.lua            (ref: require("plugins.dap"))
    completion.lua      ← from completion.lua
    highlights.lua      ← from highlights.lua
    statusline.lua      ← from statusline.lua     (ref: module-path strings in statusline/tabline exprs)
    terminal.lua        ← from terminal.lua
  plugins/              → third-party integrations
    init.lua            ← from pack-plugins.lua (packpath bootstrap, builtin disabling, vim.pack.add, PackChanged autocmd)
    treesitter.lua      ← from pack-plugins.lua (nvim-treesitter setup/install, FileType start autocmd, indentexpr, textobjects)
    dap.lua             ← from dap_pack.lua
    pick.lua            ← from pick_pack.lua
    snippet.lua         ← from snippet_pack.lua
    ai.lua              ← from ai.lua
    codecompanion.lua   ← from codecompanion_pack.lua  (ref: require("plugins.ai"))
    leetcode.lua        ← from leetcode_pack.lua
  startup.lua           ← new (VimEnter startup screen from init.lua)
scripts/                → untouched (empty)
doc/                    → untouched
nvim-pack-lock.json     → untouched
```

## Code Style

Keep existing idioms verbatim (this is a reorg, not a rewrite): 2-space indent,
`local map = vim.keymap.set` idiom, `--` comments, pcall-wrapped plugin loads
with `vim.notify`, `M`-table modules with `return M`, `lua/plugins/init.lua`
directory-module convention for the registry. Only paths, require strings, and
module-name comments change.

## Testing Strategy

No test framework exists (empty `scripts/`); verification is load + audit +
manual smoke, run after each task and fully at the end:

1. **Headless load**: `nvim --headless -c "qa"` exits 0, no error output.
2. **Grep audit** (zero hits required): command in Commands section.
3. **Manual smoke**: startup screen renders on empty args; statusline +
   bufferline render (verifies module-path strings); `<leader><space>` opens
   mini.pick; `:Leet` loads; `<leader>dd` DAP maps work; `:DapHealth` runs;
   `<C-a>` AI completion keymap exists; `:CodeCompanionChat` loads;
   `:messages` shows no errors.

## Boundaries

- **Always**: preserve behavior byte-for-byte; update every require reference;
  run headless load + grep audit after each task; keep comment style/density.
- **Ask first**: changing any keymap, option, or plugin config; renaming
  `core`/`plugins` dirs; touching `nvim-pack-lock.json`; adding dependencies or
  test infra.
- **Never**: modify `doc/*.txt` content, alter plugin behavior, reintroduce
  dead modules, commit secrets.

## Success Criteria

- [ ] `init.lua` is a thin ordered require list; all feature logic in modules.
- [ ] No `_pack`/`pack-` names anywhere; plain module names throughout.
- [ ] `core/` vs `plugins/` split consistent: core = editor behavior, plugins =
      third-party integrations.
- [ ] Dead code (`search.lua`, `fundamentals/`, `autocmd/`) gone, no dangling refs.
- [ ] Zero behavioral change: headless load clean, grep audit clean, smoke passes.
- [ ] Cross-module require paths updated: `lsp → plugins.dap`,
      `codecompanion → plugins.ai`, statusline/tabline expr strings.

## Open Questions

None — decision-complete (locked with user in plan phase).
