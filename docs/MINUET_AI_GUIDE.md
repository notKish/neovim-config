# Minuet AI (code completion)

[Minuet](https://github.com/milanglacier/minuet-ai.nvim) provides AI code completion with **ghost text** (virtual text) and integration with **blink.cmp** so you can cycle through suggestions.

## Setup

- **Provider:** DeepSeek (FIM) by default, using the `DEEPSEEK_API_KEY` environment variable (set in your Nix `secrets.nix` → `home.sessionVariables`).
- **Frontends:** Virtual text (ghost text) + blink.cmp source so completions appear in the completion menu and as inline ghost text.

## How to use (day-to-day)

1. **Type normally** in a supported filetype (python/lua/ts/js/nix/…).
2. **Ghost text**: when gray suggestion appears inline, use the **ghost-only** keymaps below to accept, cycle, or dismiss.
3. **Completion list**: use **Tab** (or your blink keys) to cycle the popup menu; use **`<C-Space>`** to trigger Minuet-only completions in the menu.

---

## Keymaps: ghost text only (inline suggestion)

Use these **only when ghost text is visible** (they do nothing otherwise). Tab is left for the completion list.

| Key        | Action                     |
|------------|----------------------------|
| `<C-CR>`   | **Accept** whole ghost (Ctrl+Enter) |
| `<S-CR>`   | Accept one line of ghost (Shift+Enter) |
| `<C-j>`    | **Next** ghost suggestion  |
| `<C-k>`    | **Previous** ghost suggestion |
| `<C-e>`    | Dismiss ghost              |

(Avoid `<C-y>` / `<M-CR>`: they conflict with blink or don’t work in terminals like Ghostty.)

---

## Keymaps: completion list (blink.cmp)

- **`<Tab>`**: open the completion menu (if not visible) and **cycle forward**; in snippets, jump to next placeholder; otherwise insert a tab.
- **`<S-Tab>`**: cycle **backward** in the menu; in snippets, jump to previous placeholder.
- **`<C-y>`**: accept the selected item (from the preset).
- **`<C-Space>`**: open the **full** completion list (LSP, path, snippets, buffer, **Minuet at the end**); use Tab / S-Tab to cycle and `<C-y>` to accept.

## Commands

- **`:Minuet change_provider`** — Switch provider (e.g. `openai_fim_compatible`, `openai_compatible`, `ollama`).
- **`:Minuet change_model`** — Change model (interactive or `provider:model`).
- **`:Minuet virtualtext toggle`** — Toggle ghost text in the current buffer.
- **`:Minuet blink toggle`** — Toggle Minuet in blink.cmp auto-completion.

## Adding other providers

Edit `lua/plugins/example.lua` and extend `provider_options`, or use `:Minuet change_provider` / `:Minuet change_model`. Examples:

- **OpenAI:** Already configured; set `OPENAI_API_KEY` in your environment, then run `:Minuet change_provider openai` (or `:Minuet change_model openai:gpt-4o-mini`).
- **Ollama (local):** `provider = "openai_fim_compatible"`, `provider_options.openai_fim_compatible` with `end_point = "http://localhost:11434/v1/completions"`, `model = "qwen2.5-coder:7b"`, `api_key = "TERM"`.
- **OpenAI-compatible (e.g. OpenRouter):** `provider = "openai_compatible"`, set `end_point` and `api_key` (env var name) in `provider_options.openai_compatible`.

Ensure the chosen API key env var is set (e.g. in Nix `home.sessionVariables` or in your shell).

## Troubleshooting

- **No completions:** Run `:Minuet change_model` and confirm provider/model; set `notify = "debug"` in minuet opts to see requests.
- **Slow / timeout:** Reduce `context_window` (e.g. 2048), increase `request_timeout`, or use a faster model.
- **DEEPSEEK_API_KEY:** Must be set in the environment where Neovim starts (e.g. from `secrets.nix` sessionVariables after a Nix rebuild).
