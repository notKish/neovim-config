# Tasks: Full Reorg of Neovim Config

Plan: `tasks/plan.md`. Spec: `SPEC.md`. Execute in order; verify after each task.

## Task 1: Split registry + treesitter

- [x] Create `lua/plugins/init.lua` (registry: packpath bootstrap, builtin-plugin
      disabling, `PackChanged` autocmd registered before `vim.pack.add`, `vim.pack.add`)
- [x] Create `lua/plugins/treesitter.lua` (nvim-treesitter setup/install, FileType
      start autocmd, indentexpr, textobjects)
- [x] Delete `lua/pack-plugins.lua`
- [x] Update `init.lua`: `require("pack-plugins")` → `require("plugins")` + `require("plugins.treesitter")`
  - Acceptance: registry + treesitter split across two files; behavior identical
  - Verify: headless load exit 0; grep audit: `pack-plugins` zero hits;
    `:TSInstallInfo`/textobjects keymaps present
  - Files: `lua/plugins/init.lua`, `lua/plugins/treesitter.lua`,
    `lua/pack-plugins.lua` (del), `init.lua`

## Task 2: Move core modules

- [x] `git mv` options, keymaps, lsp, completion, highlights, statusline,
      terminal → `lua/core/`
- [x] `lua/core/statusline.lua`: `require('statusline')` →
      `require('core.statusline')` in **both** `vim.o.tabline` and `vim.o.statusline`
- [x] `lua/core/lsp.lua`: `pcall(require, "dap_pack")` → `pcall(require, "plugins.dap")`;
      `dap_pack.jdtls_bundles()` → `dap.jdtls_bundles()`
- [x] Update `init.lua` requires for the seven core modules
  - Acceptance: core modules live in `lua/core/`; refs updated
  - Verify: headless load exit 0; grep audit: old flat paths zero hits;
    statusline/tabline render in smoke
  - Files: 7 moved files, `lua/core/statusline.lua`, `lua/core/lsp.lua`, `init.lua`

## Task 3: Move plugin modules

- [x] `git mv` ai, codecompanion_pack, dap_pack, pick_pack, snippet_pack,
      leetcode_pack → `lua/plugins/` with plain names
- [x] `lua/plugins/codecompanion.lua`: `require("ai")` → `require("plugins.ai")`
- [x] `lua/plugins/leetcode.lua`: header comment "Requires pick_pack.lua" → "lua/plugins/pick.lua"
- [x] `lua/plugins/snippet.lua`: header comment "Load after lua/lsp.lua" → "lua/core/lsp.lua"
- [x] Update `init.lua` requires for the six plugin modules
  - Acceptance: plugin modules live in `lua/plugins/` with plain names
  - Verify: headless load exit 0; grep audit zero hits; smoke AI + Leet + DAP
  - Files: 6 moved files, `lua/plugins/codecompanion.lua`,
    `lua/plugins/leetcode.lua`, `lua/plugins/snippet.lua`, `init.lua`

## Task 4: Rewrite init.lua + extract startup

- [x] Create `lua/startup.lua` with the VimEnter startup-screen block moved verbatim
- [x] Rewrite `init.lua` as thin ordered require list (order table in plan)
- [x] Remove `-- require("fundamentals")` line
  - Acceptance: init.lua is a thin require list; startup screen in `lua/startup.lua`
  - Verify: headless load exit 0; startup screen renders on empty args
  - Files: `init.lua`, `lua/startup.lua` (new)

## Task 5: Delete dead code

- [x] Remove `lua/search.lua`, `lua/fundamentals/`, `lua/autocmd/`
  - Acceptance: dead modules gone, no dangling references
  - Verify: full verification loop (load + grep audit + smoke)
  - Files: `lua/search.lua` (del), `lua/fundamentals/` (del),
    `lua/autocmd/` (del)

## Task 6: Final verification

- [x] Full verification loop: headless load, grep audit (zero hits), manual smoke
- [x] `/skill:verify` + `/skill:code-review` over the full diff
- [x] `git status` shows only expected moves/deletes/creates
  - Acceptance: all success criteria in SPEC.md met
  - Verify: SPEC.md success-criteria checklist
