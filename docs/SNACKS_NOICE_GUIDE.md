# Snacks & Noice: Configuration Guide

This guide covers **Snacks.nvim** (dashboard, picker, notifier) and **Noice.nvim** (messages, cmdline, popupmenu) as used in LazyVim. It explains what they do and how to configure them in your setup.

---

## Part 1: Snacks.nvim

**Snacks.nvim** is a collection of quality-of-life plugins for Neovim. In LazyVim it provides:

- **Dashboard** – The startup screen (Find File, New File, Projects, etc.)
- **Picker** – Fuzzy finder for files, buffers, grep, LSP, git, and 40+ sources
- **Notifier** – Pretty `vim.notify` with history
- **Other modules** – indent, input, scope, scroll, words, etc. (many enabled by LazyVim)

**Requirements:** Neovim ≥ 0.9.4. Run `:checkhealth snacks` to verify.

---

### 1.1 Opening the Dashboard

The starter screen (with **f** Find File, **n** New File, **g** Find Text, etc.) is the **Snacks dashboard**.

- **On startup:** Shown automatically when you open Neovim with no file args.
- **From anywhere:** Use the keymap **`<leader>d.`** (Space → d → .) added in `lua/config/keymaps.lua`, or call:

  ```lua
  Snacks.dashboard.open()
  ```

  Or from command line: `:lua Snacks.dashboard.open()`.

---

### 1.2 Configuring Snacks in LazyVim

LazyVim loads Snacks from its UI plugin spec. You **override** Snacks by adding a plugin spec with the same name and your `opts` in `lua/plugins/` (e.g. a new file or inside `example.lua`).

**Minimal override** – only the options you want to change:

```lua
-- In lua/plugins/example.lua (or a dedicated snacks.lua)
{
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts = opts or {}
    -- Example: notifier timeout
    opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
      timeout = 5000,
      style = "compact", -- or "minimal" | "fancy"
    })
    -- Example: dashboard – add/change a key
    opts.dashboard = opts.dashboard or {}
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.keys = opts.dashboard.preset.keys or {}
    -- Add a custom dashboard key (example)
    table.insert(opts.dashboard.preset.keys, {
      icon = " ",
      key = "R",
      desc = "Restart Neovim",
      action = ":qa | nvim",
    })
    return opts
  end,
},
```

Use `vim.tbl_deep_extend("force", defaults, your_opts)` so you don’t wipe LazyVim’s existing Snacks config.

---

### 1.3 Dashboard Configuration

Dashboard is controlled by `opts.dashboard`. Main sub-options:

| Option | Description |
|--------|-------------|
| `enabled` | Set to `false` to disable the dashboard. |
| `preset.keys` | List of items: `icon`, `key`, `desc`, `action`. `action` can be a command string (e.g. `":Lazy"`), a keymap string, or a function. |
| `preset.header` | ASCII/Unicode banner string. |
| `preset.pick` | Function used for “pick” actions (e.g. Find File). LazyVim sets this to use its picker. |
| `sections` | Full layout: list of sections like `{ section = "header" }`, `{ section = "keys", gap = 1 }`, `{ section = "recent_files", ... }`, `{ section = "startup" }`. |
| `width`, `row`, `col` | Size and position when opened in a float (e.g. `Snacks.dashboard.open()`). |
| `formats` | How items are rendered (icon, footer, file, etc.). |

**Built-in section names:** `header`, `keys`, `recent_files`, `projects`, `session`, `startup`, `terminal`.

**Example – custom keys only (keep LazyVim’s picker):**

```lua
opts.dashboard = {
  preset = {
    pick = function(cmd, opts)
      return LazyVim.pick(cmd, opts)()
    end,
    keys = {
      { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
      { icon = " ", key = "s", desc = "Restore Session", section = "session" },
      { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
      { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },
}
```

**Example – different layout with multiple panes (e.g. recent files + projects):**

```lua
opts.dashboard = {
  sections = {
    { section = "header" },
    { section = "keys", gap = 1, padding = 1 },
    { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
    { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
    { section = "startup" },
  },
}
```

You can mix `preset` (which fills in keys/header/pick) with `sections`; the docs recommend either customizing `preset` or replacing with full `sections`.

---

### 1.4 Notifier Configuration

Snacks notifier replaces or wraps `vim.notify` and shows a history.

**LazyVim keymaps:**

- `<leader>n` – Notification history (or picker notifications if Snacks picker is enabled).
- `<leader>un` – Dismiss all notifications.

**Useful opts** (under `opts.notifier`):

| Option | Default | Description |
|--------|---------|-------------|
| `timeout` | 3000 | Ms before auto-dismiss (0/false = stay until closed). |
| `width` | `{ min = 40, max = 0.4 }` | Min/max width (number or fraction of screen). |
| `height` | `{ min = 1, max = 0.6 }` | Min/max height. |
| `level` | `vim.log.levels.TRACE` | Minimum level to show (all stored in history). |
| `style` | `"compact"` | `"compact"` \| `"minimal"` \| `"fancy"`. |
| `top_down` | true | Stack notifications top-to-bottom. |
| `icons` | table | Icons per level (error, warn, info, debug, trace). |
| `filter` | nil | `function(notif) return true end` – return false to hide. |
| `keep` | function | When to keep a notification (e.g. while cmdline active). |

**Example:**

```lua
opts.notifier = {
  timeout = 5000,
  style = "minimal",
  icons = {
    error = " ",
    warn = " ",
    info = " ",
    debug = " ",
    trace = " ",
  },
}
```

**API (from Lua):**

- `Snacks.notifier.notify(msg, level, opts)` – show notification.
- `Snacks.notifier.show_history(opts)` – open history.
- `Snacks.notifier.hide(id)` – dismiss one or all.

---

### 1.5 Picker Configuration

LazyVim already wires Snacks picker to `<leader>ff`, `<leader>fr`, `<leader>sg`, etc. You can tune behavior via `opts.picker`.

**Useful options:**

| Option | Description |
|--------|-------------|
| `prompt` | Prompt text/icon (e.g. `" "`). |
| `layout.preset` | `"default"`, `"vertical"`, `"ivy"`, `"sidebar"`, `"vscode"`, etc. |
| `layout.cycle` | Allow cycling layout (e.g. `<C-H/J/K/L>`). |
| `matcher.fuzzy` | Fuzzy matching on/off. |
| `matcher.ignorecase`, `smartcase` | Case behavior. |
| `matcher.sort_empty` | Sort when search string is empty. |
| `focus` | `"input"` or `"list"` on open. |
| `show_delay` | Ms before showing when there are no results yet. |
| `win.input.keys`, `win.list.keys` | Keymaps in input and list. |
| `formatters.file.truncate` | `"left"` \| `"center"` \| `"right"` for paths. |
| `toggles` | e.g. follow, hidden, ignored, modified, regex. |

**Example – different default layout and prompt:**

```lua
opts.picker = {
  prompt = " ",
  layout = {
    cycle = true,
    preset = "vertical", -- or function() return vim.o.columns >= 120 and "default" or "vertical" end
  },
  focus = "input",
}
```

**Sources (examples):** `Snacks.picker.files()`, `Snacks.picker.buffers()`, `Snacks.picker.grep()`, `Snacks.picker.lsp_symbols()`, `Snacks.picker.git_status()`, `Snacks.picker.diagnostics()`, `Snacks.picker.recent()`, `Snacks.picker.projects()`, and many more (see `:h snacks-picker` or the picker docs).

---

### 1.6 Other Snacks Modules (Brief)

- **indent** – Indent guides.
- **input** – Better `vim.ui.input`.
- **scope** – Scope detection and text objects.
- **scroll** – Smooth scrolling.
- **words** – LSP references overlay and navigation.

Enable/disable or configure them under `opts` with the same key (e.g. `opts.indent = { enabled = true }`). See the [Snacks README](https://github.com/folke/snacks.nvim) and `doc/` for each module.

---

## Part 2: Noice.nvim

**Noice.nvim** replaces the default UI for:

- **Messages** – `:messages`, echo, and other msg_show events.
- **Cmdline** – `:`, `/`, `?`, and input prompts.
- **Popupmenu** – Completion menu (when backend is `nui`).

So you get a consistent, configurable look for commands, search, messages, and (optionally) completion.

**Requirements:** Neovim ≥ 0.9.0 (nightly recommended), **nui.nvim**. Optional: **nvim-notify**, **nvim-treesitter** (for cmdline/LSP doc highlighting). Run `:checkhealth noice` after installing.

---

### 2.1 Noice Commands & Keymaps (LazyVim)

| Command | Description |
|---------|-------------|
| `:Noice` / `:Noice history` | Message history. |
| `:Noice last` | Last message in a popup. |
| `:Noice errors` | Error messages. |
| `:Noice dismiss` | Dismiss visible messages. |
| `:Noice disable` / `:Noice enable` | Toggle Noice. |
| `:Noice telescope` | Message history in Telescope. |

**LazyVim keymaps (under `<leader>sn`):**

- `<leader>sn` – Noice submenu.
- `<leader>snl` – Noice last message.
- `<leader>snh` – Noice history.
- `<leader>sna` – Noice all.
- `<leader>snd` – Dismiss all.
- `<leader>snt` – Noice picker (Telescope/FzfLua).

**Cmdline redirect:** In command line, **`<S-Enter>`** redirects the current cmdline output to a Noice popup (so you can scroll/copy).

---

### 2.2 Configuring Noice in LazyVim

LazyVim loads Noice in its UI plugin. Override by adding a spec for `"folke/noice.nvim"` in `lua/plugins/` and passing your `opts`.

**Structure of `opts`:**

- **cmdline** – Cmdline UI (view, format, icons).
- **messages** – Where messages go (view, view_error, view_warn, view_history, view_search).
- **popupmenu** – Completion UI (backend `nui` or `cmp`, kind_icons).
- **lsp** – Progress, hover, signature, documentation overrides.
- **routes** – Filter + view for specific messages.
- **views** – Override built-in view options (size, position, border, etc.).
- **presets** – Quick presets (bottom_search, command_palette, long_message_to_split, etc.).
- **format** – Level icons, default format strings.

**Minimal override example:**

```lua
{
  "folke/noice.nvim",
  opts = function(_, opts)
    opts = opts or {}
    opts.presets = vim.tbl_extend("force", opts.presets or {}, {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      lsp_doc_border = false,
    })
    return opts
  end,
},
```

---

### 2.3 Noice Presets

| Preset | Effect |
|--------|--------|
| `bottom_search` | Search cmdline at bottom (classic style). |
| `command_palette` | Cmdline and popupmenu shown together. |
| `long_message_to_split` | Long messages go to a split. |
| `inc_rename` | Input dialog for inc-rename. |
| `lsp_doc_border` | Border on hover/signature help. |

Enable in `opts.presets`:

```lua
presets = {
  bottom_search = true,
  command_palette = true,
  long_message_to_split = true,
  lsp_doc_border = false,
},
```

---

### 2.4 Cmdline Configuration

**Options under `opts.cmdline`:**

- `enabled` – Turn cmdline UI on/off.
- `view` – `"cmdline_popup"` (fancy) or `"cmdline"` (classic bottom line).
- `format` – Map cmdline *type* to icon and lang (for syntax):
  - `cmdline` – `:`
  - `search_down` – `/`
  - `search_up` – `?`
  - `filter` – `:!`
  - `lua` – `:lua`
  - `help` – `:help`
  - `input` – for `vim.fn.input()` style prompts.

**Example – simpler icons (no Nerd Font):**

```lua
cmdline = {
  format = {
    cmdline = { icon = ">" },
    search_down = { icon = "?" },
    search_up = { icon = "?" },
    filter = { icon = "$" },
    lua = { icon = "" },
    help = { icon = "?" },
  },
},
```

---

### 2.5 Messages and Routes

**Messages:**

- `view` – Default view for messages (e.g. `"notify"`).
- `view_error`, `view_warn` – Views for errors/warnings.
- `view_history` – View for `:messages` (e.g. `"messages"` = split).
- `view_search` – Search count (e.g. `"virtualtext"` or `false` to disable).

**Routes** control which messages go where. Each route has:

- `filter` – When the route applies (event, kind, min_height, etc.).
- `view` – View name.
- `opts` – e.g. `skip = true` (don’t show), `stop = true` (don’t run later routes).

**Example – skip search count:**

```lua
routes = {
  {
    filter = { event = "msg_show", kind = "search_count" },
    opts = { skip = true },
  },
},
```

**Example – long messages to split:**

```lua
routes = {
  {
    view = "split",
    filter = { event = "msg_show", min_height = 20 },
  },
},
```

**Filter fields (short list):** `event`, `kind`, `error`, `warning`, `min_height`, `max_height`, `find` (pattern), `not` (inverted filter).

---

### 2.6 Views

Noice views are combinations of **backend** (popup, split, notify, virtualtext, mini) and options. Built-in view names include: `notify`, `split`, `vsplit`, `popup`, `mini`, `cmdline`, `cmdline_popup`, `messages`, `hover`, `confirm`, `popupmenu`.

Override options in `opts.views`:

```lua
views = {
  split = {
    enter = true,
    size = 0.3,
  },
  popup = {
    border = { style = "rounded" },
  },
},
```

---

### 2.7 LSP Overrides

Noice can override LSP hover and signature help and optionally markdown rendering for cmp/LSP:

```lua
lsp = {
  progress = { enabled = true, view = "mini" },
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true, -- if using nvim-cmp
  },
  hover = { enabled = true, view = nil, opts = {} },
  signature = { enabled = true, auto_open = { ... } },
  message = { enabled = true, view = "notify" },
  documentation = { view = "hover", opts = { ... } },
},
```

---

### 2.8 Statusline and Redirect

**Statusline:** Noice provides components like `require("noice").api.status.message.get_hl`, `require("noice").api.status.command.get`, `require("noice").api.status.mode.get`, `require("noice").api.status.search.get`. Use them in your statusline (e.g. lualine) with the right `cond` so they only show when the component is active.

**Redirect:** From Lua you can redirect command output to Noice:

```lua
require("noice").redirect("hi")
require("noice").redirect(function()
  print("something")
end)
```

The `<S-Enter>` keymap in cmdline mode redirects the current cmdline (see LazyVim’s noice spec).

---

## Quick Reference

### Snacks

| Task | How |
|------|-----|
| Open dashboard | `<leader>d.` or `:lua Snacks.dashboard.open()` |
| Notification history | `<leader>n` |
| Dismiss notifications | `<leader>un` |
| Configure | Override `opts` in a `"folke/snacks.nvim"` spec (dashboard, notifier, picker, etc.). |
| Health check | `:checkhealth snacks` |

### Noice

| Task | How |
|------|-----|
| Message history | `:Noice` or `<leader>snh` |
| Last message | `:Noice last` or `<leader>snl` |
| Dismiss all | `:Noice dismiss` or `<leader>snd` |
| Redirect cmdline | `<S-Enter>` in cmdline mode |
| Configure | Override `opts` in a `"folke/noice.nvim"` spec (presets, cmdline, messages, routes, views). |
| Health check | `:checkhealth noice` |

---

## References

- [Snacks.nvim](https://github.com/folke/snacks.nvim) – README and `docs/` (dashboard, notifier, picker, etc.).
- [Noice.nvim](https://github.com/folke/noice.nvim) – README and [Configuration Recipes](https://github.com/folke/noice.nvim/wiki/Configuration-Recipes).
- LazyVim: `lua/lazyvim/plugins/ui.lua` (Snacks/Noice specs) and [LazyVim keymaps](https://www.lazyvim.org/keymaps).
