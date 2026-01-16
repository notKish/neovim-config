# UV Guide: Fast Python Package Management

## Overview

**uv** is an extremely fast Python package installer and resolver written in Rust. It's designed as a drop-in replacement for `pip`, `pip-tools`, `poetry`, `pipenv`, `pyenv`, `twine`, `virtualenv`, and more.

## Why UV?

- ⚡ **10-100x faster** than pip/poetry
- 🔒 **Lock files** for reproducibility (`uv.lock`)
- 🎯 **Better dependency resolution** than pip
- 🔄 **Compatible** with pip, requirements.txt, pyproject.toml
- 🛠️ **All-in-one tool** - installer, resolver, virtualenv manager

## Installation

UV is already added to your Nix flake. After rebuilding, it will be available:

```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
```

Verify installation:
```bash
uv --version
```

## Basic Usage

### Initialize a New Project

```bash
# Create a new project
uv init my-project
cd my-project

# Or initialize in current directory
uv init
```

This creates:
- `pyproject.toml` - Project configuration and dependencies
- `.python-version` - Python version specification
- `uv.lock` - Lock file (after first sync)

### Add Dependencies

```bash
# Add a package
uv add requests

# Add a dev dependency
uv add --dev pytest black

# Add with version constraint
uv add "django>=4.0,<5.0"

# Add from git
uv add git+https://github.com/user/repo.git
```

### Install from requirements.txt

```bash
# Install from requirements.txt (compatible with pip)
uv pip install -r requirements.txt

# Or sync (creates lock file)
uv pip sync requirements.txt
```

### Sync Dependencies

```bash
# Install all dependencies from pyproject.toml
uv sync

# Sync and install dev dependencies
uv sync --dev

# Sync with specific Python version
uv sync --python 3.11
```

## Virtual Environment Management

### Automatic venv (Recommended)

UV automatically manages virtual environments. Just use commands:

```bash
uv add requests  # Automatically creates/uses .venv
uv run python script.py  # Runs in venv automatically
```

### Manual venv Control

```bash
# Create venv
uv venv

# Create venv with specific Python version
uv venv --python 3.11

# Activate venv (or use direnv)
source .venv/bin/activate
```

### With Direnv

UV works perfectly with direnv. Here's the recommended `.envrc`:

```bash
# .envrc
# UV + Direnv integration
# UV automatically manages .venv, but we ensure it exists and is activated

# Create venv with UV if pyproject.toml exists, otherwise use python3
if [ -f pyproject.toml ]; then
  # UV project - let UV manage the venv
  uv venv --quiet 2>/dev/null || true
  source .venv/bin/activate
else
  # Not a UV project yet - use standard layout
  layout python3
fi

# Ensure UV uses the project venv
export UV_PROJECT_ENVIRONMENT=.venv
```

**Simpler alternative** (if you always use UV):

```bash
# .envrc
layout python3
export UV_PROJECT_ENVIRONMENT=.venv
```

This ensures:
- ✅ UV uses the correct venv
- ✅ Works with both UV projects and regular Python projects
- ✅ Automatic venv activation when entering directory

## Project Setup Workflow

### New Project

```bash
# 1. Create project
mkdir my-project && cd my-project

# 2. Initialize UV project
uv init

# 3. Set up direnv (use the template or create manually)
cp ~/.config/nvim/.envrc.template .envrc
# Or create manually:
cat > .envrc << 'EOF'
if [ -f pyproject.toml ]; then
  uv venv --quiet 2>/dev/null || true
  source .venv/bin/activate
else
  layout python3
fi
export UV_PROJECT_ENVIRONMENT=.venv
EOF

direnv allow

# 4. Add dependencies
uv add requests flask
uv add --dev pytest ruff

# 5. Sync (installs everything)
uv sync

# 6. Start coding!
uv run python main.py
```

### Existing Project (requirements.txt)

```bash
# 1. Install from requirements.txt
uv pip install -r requirements.txt

# 2. Generate lock file
uv pip compile requirements.txt -o requirements.lock

# 3. Or migrate to pyproject.toml
uv pip compile requirements.txt --format pyproject
```

### Existing Project (poetry/pipenv)

```bash
# UV can read pyproject.toml directly
uv sync

# Or convert poetry.lock
uv lock --format poetry
```

## Common Commands

### Package Management

```bash
# Add package
uv add package-name

# Remove package
uv remove package-name

# Update package
uv lock --upgrade-package package-name

# Update all packages
uv lock --upgrade

# List installed packages
uv pip list

# Show package info
uv pip show package-name
```

### Running Scripts

```bash
# Run Python script in venv
uv run python script.py

# Run with specific Python version
uv run --python 3.11 python script.py

# Run command in venv
uv run pytest

# Run with environment variables
uv run --env VAR=value python script.py
```

### Development Tools

```bash
# Run linter
uv run ruff check .

# Run formatter
uv run ruff format .

# Run tests
uv run pytest

# Run with coverage
uv run pytest --cov
```

## Integration with Neovim

### LSP (pyright)

UV works seamlessly with pyright. Just ensure your venv is activated:

```bash
# In your project
uv sync

# Neovim will automatically detect .venv
# pyright will use packages from venv
```

### Formatters/Linters

```bash
# Add ruff to project
uv add --dev ruff

# Neovim will use ruff from .venv automatically
```

## Advanced Usage

### Multiple Python Versions

```bash
# Install specific Python version
uv python install 3.11

# Use specific version for project
uv sync --python 3.11

# List installed Python versions
uv python list
```

### Lock Files

```bash
# Generate lock file
uv lock

# Update lock file
uv lock --upgrade

# Check for outdated packages
uv lock --check
```

### Publishing Packages

```bash
# Build package
uv build

# Publish to PyPI
uv publish
```

### Workspace Support

UV supports monorepos with multiple projects:

```pyproject.toml
[tool.uv.workspace]
members = ["project1", "project2", "project3"]
```

## Comparison with Other Tools

| Feature | uv | pip | poetry | pipenv |
|---------|----|----|--------|--------|
| Speed | ⚡⚡⚡ | ⚡ | ⚡⚡ | ⚡ |
| Lock files | ✅ | ❌ | ✅ | ✅ |
| Dependency resolution | Excellent | Basic | Good | Good |
| Virtualenv management | ✅ | ❌ | ✅ | ✅ |
| requirements.txt support | ✅ | ✅ | ❌ | ❌ |
| pyproject.toml support | ✅ | Partial | ✅ | ❌ |

## Best Practices

### 1. Use pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
dependencies = [
    "requests>=2.31.0",
    "flask>=3.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "ruff>=0.1.0",
]
```

### 2. Commit Lock Files

```bash
# Always commit uv.lock
git add uv.lock
git commit -m "Update dependencies"
```

### 3. Use Version Constraints

```bash
# Good: Specify version ranges
uv add "django>=4.0,<5.0"

# Avoid: Pinning exact versions (unless necessary)
uv add "django==4.2.0"  # Only if you need exact version
```

### 4. Separate Dev Dependencies

```bash
# Production dependencies
uv add requests flask

# Dev dependencies
uv add --dev pytest ruff mypy
```

### 5. Use UV Run for Scripts

```bash
# Instead of activating venv manually
uv run python script.py
uv run pytest
uv run ruff check .
```

## Troubleshooting

### Issue: UV Not Found

**Solution:**
```bash
# Rebuild Nix
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro

# Verify
which uv
uv --version
```

### Issue: Lock File Conflicts

**Solution:**
```bash
# Regenerate lock file
uv lock --upgrade

# Or remove and recreate
rm uv.lock
uv sync
```

### Issue: Dependency Resolution Fails

**Solution:**
```bash
# Check for conflicts
uv lock --check

# Try upgrading specific packages
uv lock --upgrade-package problematic-package

# Or use pip fallback for specific packages
uv pip install problematic-package
```

### Issue: Python Version Not Found

**Solution:**
```bash
# Install Python version
uv python install 3.11

# Or use system Python
uv sync --python $(which python3)
```

## Migration Guide

### From pip/requirements.txt

```bash
# 1. Install packages
uv pip install -r requirements.txt

# 2. Generate pyproject.toml
uv pip compile requirements.txt --format pyproject > pyproject.toml

# 3. Generate lock file
uv lock
```

### From Poetry

```bash
# 1. UV can read pyproject.toml directly
uv sync

# 2. Generate UV lock file
uv lock
```

### From pipenv

```bash
# 1. Export to requirements.txt
pipenv requirements > requirements.txt

# 2. Use UV
uv pip install -r requirements.txt
uv pip compile requirements.txt --format pyproject > pyproject.toml
```

## Example Project Structure

```
my-project/
├── .envrc              # direnv config: layout python3
├── .gitignore
├── pyproject.toml      # UV project config
├── uv.lock             # Lock file (committed)
├── .venv/              # Virtual environment (gitignored)
├── src/
│   └── main.py
├── tests/
│   └── test_main.py
└── README.md
```

## Quick Reference

```bash
# Project setup
uv init
uv add package
uv sync

# Running
uv run python script.py
uv run pytest

# Management
uv lock
uv lock --upgrade
uv remove package

# Python versions
uv python install 3.11
uv python list
```

## Resources

- **UV Documentation**: https://github.com/astral-sh/uv
- **UV GitHub**: https://github.com/astral-sh/uv
- **PyPI**: https://pypi.org/project/uv/

## Summary

UV is the fastest and most modern Python package manager. It combines the best features of pip, poetry, and pipenv while being 10-100x faster. Perfect for complex projects that need:

- ⚡ Fast dependency resolution
- 🔒 Reproducible builds (lock files)
- 🎯 Better dependency management
- 🔄 Compatibility with existing tools

Use UV for all your Python projects!
