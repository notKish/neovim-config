# Claude Code in LazyVim

This config uses the **LazyVim Claude Code extra** (`lazyvim.plugins.extras.ai.claudecode`), which integrates [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) — the Neovim IDE extension for Anthropic’s Claude Code CLI.

## Requirements

- **Neovim** (≥ 0.8)
- **Claude Code CLI** installed and logged in ([Claude Code docs](https://docs.anthropic.com/en/docs/claude-code))
- **folke/snacks.nvim** (pulled in by the extra for terminal support)

## Setup

1. **Enable the extra** (already done in this config via `lua/plugins/example.lua`):
   ```lua
   { import = "lazyvim.plugins.extras.ai.claudecode" }
   ```

2. **Install Claude Code CLI via Nix** (this config’s flake already includes it):
   - The `~/.config/nix` flake adds [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix) and exposes the **native binary** (no Node/npm). Rebuild so `claude` is on your PATH:
     ```bash
     darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
     ```
   - Then auth (once):
     ```bash
     claude auth   # log in when prompted
     claude doctor # verify installation
     ```

3. **If `claude` isn’t on PATH inside Neovim** (e.g. GUI), set the full path in your plugin opts:
   ```lua
   opts = { terminal_cmd = "/path/to/claude" }  -- use output of: which claude
   ```

## Keymaps (all under `<leader>a`)

| Key       | Mode   | Action                |
|----------|--------|------------------------|
| `<leader>a`  | n, v   | AI group (prefix)      |
| `<leader>ac`  | n      | Toggle Claude          |
| `<leader>af`  | n      | Focus Claude           |
| `<leader>ar`  | n      | Resume Claude          |
| `<leader>aC`  | n      | Continue Claude        |
| `<leader>ab`  | n      | Add current buffer     |
| `<leader>as`  | v      | Send selection to Claude |
| `<leader>as`  | n (tree) | Add file (NvimTree / neo-tree / oil) |
| `<leader>aa`  | n      | Accept diff            |
| `<leader>ad`  | n      | Deny diff              |

## Commands

- **`:ClaudeCode`** — Toggle Claude Code terminal (split).
- **`:ClaudeCodeFocus`** — Focus or toggle the Claude terminal.
- **`:ClaudeCode --resume`** — Resume previous session.
- **`:ClaudeCode --continue`** — Continue last conversation.
- **`:ClaudeCodeSend`** — Send current visual selection to Claude (same as `<leader>as` in visual mode).
- **`:ClaudeCodeAdd [file] [start-line] [end-line]`** — Add file (and optional line range) to context.
- **`:ClaudeCodeDiffAccept`** — Accept proposed diff.
- **`:ClaudeCodeDiffDeny`** — Reject proposed diff.
- **`:ClaudeCodeStatus`** — Show connection status (useful for debugging).

## Workflow

1. **Start Claude** — `<leader>ac` or `:ClaudeCode`. A terminal split opens and the CLI connects to Neovim via WebSocket (same protocol as the official VS Code extension).
2. **Add context** — Use `<leader>ab` to add the current buffer, or select text and `<leader>as` to send a selection. In a file tree (NvimTree, neo-tree, oil), `as` on a file adds it to context.
3. **Chat and edit** — Claude can see your buffers and selections, open files, and propose edits. When it suggests changes, a diff view opens.
4. **Apply or reject** — In the diff window: save (`:w`) or `<leader>aa` to accept; `:q` or `<leader>ad` to deny. You can edit the proposal before accepting.

## Troubleshooting

- **Claude doesn’t connect** — Run `:ClaudeCodeStatus` and check for a lock file in `~/.claude/ide/` (or `$CLAUDE_CONFIG_DIR/ide/` if set). Ensure the CLI is installed and `claude doctor` passes.
- **More logs** — In the plugin opts, set `log_level = "debug"`.
- **Terminal issues** — Try `terminal = { provider = "native" }` in opts if you have problems with the default (snacks) terminal.
- **Claude not on PATH** — If Neovim doesn’t see `claude` (e.g. running from a GUI), set `opts = { terminal_cmd = "/path/to/claude" }` to the Nix store path from `which claude`.

## References

- [LazyVim Claudecode extra](https://www.lazyvim.org/extras/ai/claudecode)
- [claudecode.nvim repo](https://github.com/coder/claudecode.nvim)
- [Claude Code CLI docs](https://docs.anthropic.com/en/docs/claude-code)
