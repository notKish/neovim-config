# 💤 LazyVim

## Pre-requisites

- nvim 0.11+
- ripgrep
- For Python: login to the virtual environment (or use direnv - see [DIRENV_GUIDE.md](DIRENV_GUIDE.md))

## Documentation

- **[SETUP_COMPLETE.md](SETUP_COMPLETE.md)** - **READ FIRST** - Summary of what's configured and final steps
- **[QUICK_START_UV.md](QUICK_START_UV.md)** - **START HERE** - Complete 5-minute setup guide for UV + Direnv + Neovim
- **[NEXT_STEPS.md](NEXT_STEPS.md)** - Testing and using your Python setup
- **[UV_GUIDE.md](UV_GUIDE.md)** - Complete guide to UV: fast Python package management (recommended for complex projects)
- **[UV_DIRENV_TEMPLATE.md](UV_DIRENV_TEMPLATE.md)** - Reusable .envrc template for UV projects
- **[LAZYVIM_EXTRAS.md](LAZYVIM_EXTRAS.md)** - Guide to LazyVim extras: what they contain, how to customize them
- **[DIRENV_GUIDE.md](DIRENV_GUIDE.md)** - Complete guide to using direnv for Python and other languages with automatic environment switching
- **[DIRENV_SIMPLE_SETUP.md](DIRENV_SIMPLE_SETUP.md)** - Simple direnv setup options (no flake.nix needed)

## Configuration

This setup uses:
- **Nix** for package management (no Mason)
- **LazyVim extras** for language support
- **Direnv** for automatic environment switching
- **UV** for fast Python package management (recommended for complex projects)
- **Pyright** for Python LSP
- **Ruff** for Python formatting and linting

## Todo

- [x] Switching between previously active buffer (jump list navigation)
- [x] Yank should copy into clipboard and buffer, paste can from c-v and or p. Also highlight text on copy/paste for 0.5 sec
- [x] Configure DAP for TypeScript for nvim version
- [x] Python integration with pyright and ruff
- [x] Automatic environment switching with direnv
