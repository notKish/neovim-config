# LazyVim Extras Guide

## Overview

LazyVim extras are modular configuration packages that add language support, UI enhancements, and development tools to your Neovim setup. They can be easily enabled/disabled and customized to fit your needs.

## Managing Extras

### Viewing Available Extras

Use the `:LazyExtras` command in Neovim to see all available extras organized by category:
- **Language Support** (`lang.*`) - Python, TypeScript, Rust, Go, etc.
- **UI Enhancements** (`ui.*`) - Dashboards, status lines, themes
- **Coding Utilities** (`coding.*`) - Refactoring, navigation tools
- **Editor Enhancements** (`editor.*`) - Advanced search, file management
- **Utilities** (`util.*`) - Workflow improvements

### Enabling Extras

Add extras to your `lua/plugins/example.lua`:

```lua
return {
  -- Import extras
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.ui.alpha" },
}
```

## Common Language Extras

### Python (`lang.python`)

**What it includes:**
- `pyright` LSP server configuration
- `venv-selector.nvim` for virtual environment management
- Python treesitter parsers (python, ninja, rst)
- `neotest-python` for testing (if neotest installed)
- `nvim-dap-python` for debugging (if nvim-dap installed)
- Auto-bracket completion for Python (if nvim-cmp installed)

**What it does NOT include:**
- Ruff formatter/linter (you need to add this separately)
- Custom pyright settings (you can override these)

**Customization example:**
```lua
-- Override pyright settings
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        settings = {
          pyright = {
            useLibraryCodeForTypes = true,
          },
          python = {
            analysis = {
              autoImportCompletions = true,
              typeCheckingMode = "basic",
            },
          },
        },
      },
    },
  },
},
```

**Project-level `pyrightconfig.json` (optional):**
To match this config’s Pyright behavior from a file (e.g. for CLI `pyright` or other editors), put this in your project root:

```json
{
  "$schema": "https://raw.githubusercontent.com/microsoft/pyright/main/packages/vscode-pyright/schemas/pyrightconfig.schema.json",
  "include": ["."],
  "exclude": [
    "**/node_modules",
    "**/__pycache__",
    "**/.*",
    "**/venv",
    "**/.venv",
    "**/env",
    "**/.env",
    "**/build",
    "**/dist",
    "**/.git"
  ],
  "typeCheckingMode": "basic",
  "useLibraryCodeForTypes": false
}
```
or
```json
{
  "venvPath": ".",
  "venv": ".venv",
  "pythonVersion": "3.11",
  "pythonPlatform": "Darwin"
}

```

Pyright (and the Neovim LSP) will use this when the file is in the project root. The LSP in this config also sets `diagnosticMode: "openFilesOnly"` and `autoSearchPaths: false` via Lua; those are applied in-editor only.

### Go (`lang.go`)

**What it includes:** gopls (LSP), treesitter (go, gomod, gowork, gosum), conform (gofumpt), nvim-lint (golangci-lint), nvim-dap-go. Tools (go, gopls, gofumpt, delve, golangci-lint) are provided by Nix.

**Why `go-service/internal/service` (or any internal package) might not import:**

1. **Import path must match the module path**
   Imports use the **module path from `go.mod`**, not the repo folder name.
   - If `go.mod` has `module github.com/you/go-service`, use:
     ```go
     import "github.com/you/go-service/internal/service"
     ```
   - Not `go-service/internal/service` unless your module line is literally `module go-service`.

2. **Open from the module root**
   gopls must run with the directory that contains `go.mod` as the workspace root.
   - Open the project as the root: `nvim /path/to/go-service` (where `go.mod` lives), not a subfolder.
   - If you use a parent repo with several Go modules, use a **go.work** file or open each module root in its own Neovim session.

3. **Go’s `internal` rule**
   Code in `internal/` may only be imported by code in the **same module** whose directory is at or above that `internal` directory.
   - So `internal/service` can be imported from `cmd/` or `pkg/` in the same module.
   - It cannot be imported from another module (e.g. a different `go.mod` or a different repo).

4. **After changing `go.mod` or layout**
   Run from the project root:
   ```bash
   go mod tidy
   ```
   Then restart gopls (`:LspRestart`) or Neovim so it rescans.

**Quick check:** From the directory that contains `go.mod`, run:
```bash
go list ./...
```
If that lists your packages, use the **exact** import paths it shows (e.g. `github.com/you/go-service/internal/service`) in your imports.

### TypeScript (`lang.typescript`)

**What it includes:**
- `vtsls` or `typescript-language-server` LSP
- TypeScript/TSX treesitter parsers
- `typescript.nvim` for advanced TypeScript features
- Organize imports functionality

**Customization:**
```lua
{
  "jose-elias-alvarez/typescript.nvim",
  keys = {
    { "<leader>co", "<cmd>TypescriptOrganizeImports<cr>", desc = "Organize Imports" },
    { "<leader>cR", "<cmd>TypescriptRenameFile<cr>", desc = "Rename File" },
  },
}
```

### JSON (`lang.json`)

**What it includes:**
- JSON LSP server
- JSON treesitter parser
- JSON schema validation

## UI Extras

### Alpha (`ui.alpha`)

**What it includes:**
- Customizable dashboard on startup
- Uses `alpha-nvim` plugin
- Shows recent files, bookmarks, and quick actions

### Mini Starter (`ui.mini-starter`)

**What it includes:**
- Minimal dashboard using `mini.starter`
- Lightweight alternative to Alpha

## How to Customize Extras

### Method 1: Override Plugin Options

You can override any plugin's options that are configured by an extra:

```lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },

  -- Override venv-selector settings
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      notify_user_on_activate = true,
    },
  },
}
```

### Method 2: Add Additional Configuration

Extras provide base configurations, but you can add more:

```lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },

  -- Add ruff formatter (not included in Python extra)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format" }
      return opts
    end,
  },
}
```

### Method 3: Disable Specific Plugins from an Extra

If an extra includes a plugin you don't want:

```lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },

  -- Disable a plugin that comes with the extra
  { "some-plugin-from-extra", enabled = false },
}
```

### Method 4: Conditional Configuration

Configure extras based on conditions:

```lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Only add custom settings if using Nix (not Mason)
      if vim.g.mason_disable then
        opts.servers.pyright = {
          settings = {
            -- Custom settings for Nix-provided pyright
          },
        }
      end
      return opts
    end,
  },
}
```

## Finding What an Extra Contains

### Method 1: Check LazyVim Documentation

Visit: https://www.lazyvim.org/extras

Each extra has its own page documenting what it includes.

### Method 2: Inspect in Neovim

```lua
-- Check what plugins an extra loads
:LazyExtras

-- Or check plugin source
:lua print(vim.inspect(require("lazy").plugins()))
```

### Method 3: Check Plugin Dependencies

After loading an extra, check what it configured:

```lua
-- In Neovim, check formatters
:lua print(vim.inspect(require("conform").formatters_by_ft))

-- Check LSP servers
:lua print(vim.inspect(require("lspconfig").util.available_servers()))

-- Check linters
:lua print(vim.inspect(require("lint").linters_by_ft))
```

## Best Practices

1. **Start with extras**: Use extras for base functionality, then customize
2. **Don't duplicate**: Check what an extra provides before adding your own config
3. **Override, don't replace**: Use `opts` functions to merge with extra configs
4. **Document your customizations**: Add comments explaining why you're overriding
5. **Test after changes**: Verify your customizations work with the extra

## Common Customization Patterns

### Adding Formatters/Linters Not in Extras

```lua
{
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters = opts.formatters or {}
    opts.formatters.my_formatter = {
      command = "my-tool",
      args = { "format", "$FILENAME" },
    }
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.python = { "my_formatter" }
    return opts
  end,
}
```

### Customizing LSP Settings

```lua
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        settings = {
          -- Your custom settings
        },
      },
    },
  },
}
```

### Adding Keybindings

```lua
{
  "some-plugin-from-extra",
  keys = {
    { "<leader>xx", "<cmd>SomeCommand<cr>", desc = "Custom command" },
  },
}
```

## Troubleshooting

### Extra Not Loading

1. Check syntax in `lua/plugins/example.lua`
2. Run `:Lazy` to see if there are errors
3. Check `:LazyExtras` to verify the extra is enabled

### Conflicts with Custom Config

1. Check what the extra configures first
2. Use `opts` functions to merge, not replace
3. Disable conflicting plugins if needed

### Missing Functionality

1. Check the extra's documentation
2. Some features require additional plugins (e.g., DAP requires nvim-dap)
3. Add missing tools manually if not included

## Resources

- **Official Docs**: https://www.lazyvim.org/extras
- **LazyVim GitHub**: https://github.com/LazyVim/LazyVim
- **Plugin Manager**: https://github.com/folke/lazy.nvim
