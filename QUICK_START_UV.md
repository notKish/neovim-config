# Quick Start: UV + Direnv + Neovim

## Complete Setup in 5 Minutes

This guide walks you through setting up a Python project with UV, direnv, and Neovim.

## Prerequisites

✅ Nix flake rebuilt (UV installed)  
✅ Direnv configured  
✅ Neovim configured with Python extras

## Step-by-Step Setup

### 1. Create New Project

```bash
mkdir my-python-project
cd my-python-project
```

### 2. Set Up Direnv

```bash
# Copy the UV + direnv template
cat > .envrc << 'EOF'
# UV + Direnv integration
if [ -f pyproject.toml ]; then
  uv venv --quiet 2>/dev/null || true
  source .venv/bin/activate
else
  layout python3
fi
export UV_PROJECT_ENVIRONMENT=.venv
EOF

# Allow direnv
direnv allow
```

### 3. Initialize UV Project

```bash
# Initialize UV project (creates pyproject.toml)
uv init

# Add some dependencies
uv add requests
uv add --dev pytest ruff

# Sync (installs everything)
uv sync
```

### 4. Create a Simple Python File

```bash
cat > main.py << 'EOF'
import requests

def fetch_data(url: str) -> dict:
    """Fetch data from a URL."""
    response = requests.get(url)
    return response.json()

if __name__ == "__main__":
    data = fetch_data("https://api.github.com")
    print(f"GitHub API status: {data.get('current_user_url', 'OK')}")
EOF
```

### 5. Test Everything

```bash
# Test Python execution
python main.py

# Test UV run
uv run python main.py

# Test imports work
python -c "import requests; print('✅ requests installed')"

# Check venv
which python
# Should show: /path/to/my-python-project/.venv/bin/python
```

### 6. Open in Neovim

```bash
nvim main.py
```

**In Neovim, verify:**
- `:LspInfo` - Should show pyright attached
- Hover over `requests` - Should show type information
- `:Format` or `<leader>cf` - Should format with ruff
- `:Lint` - Should show any linting errors

## Verification Checklist

- [ ] `which python` shows `.venv/bin/python`
- [ ] `uv pip list` shows installed packages
- [ ] `python -c "import requests"` works
- [ ] Neovim shows pyright LSP active
- [ ] Formatting works (`<leader>cf`)
- [ ] Linting works (`:Lint`)

## Common Workflows

### Adding New Dependencies

```bash
# Add production dependency
uv add flask

# Add dev dependency
uv add --dev mypy

# Sync to install
uv sync
```

### Running Scripts

```bash
# Run with UV (automatically uses venv)
uv run python main.py

# Or activate venv and run normally
python main.py  # Works because direnv activated venv
```

### Running Tests

```bash
# Run tests
uv run pytest

# Or
pytest  # Works because venv is activated
```

### Formatting and Linting

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check .

# Or use Neovim:
# <leader>cf - Format
# :Lint - Lint
```

## Project Structure

After setup, your project should look like:

```
my-python-project/
├── .envrc              # Direnv config (UV integrated)
├── .gitignore
├── pyproject.toml      # UV project config
├── uv.lock             # Lock file (commit this!)
├── .venv/              # Virtual environment (gitignored)
├── main.py             # Your code
└── README.md
```

## Troubleshooting

### UV Not Found

```bash
# Rebuild Nix
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro

# Verify
which uv
```

### Direnv Not Activating

```bash
# Check if allowed
direnv allow

# Check hook
echo $DIRENV_SHELL

# If missing, add to ~/.zshrc:
eval "$(direnv hook zsh)"
```

### LSP Not Working in Neovim

```bash
# Check Python path
:echo system('which python')

# Should show .venv path
# If not, restart Neovim after direnv activates
```

### Packages Not Found

```bash
# Re-sync
uv sync

# Check installation
uv pip list

# Verify venv
which python
```

## Next Steps

1. **Add more dependencies** as needed
2. **Write your code** - LSP, formatting, linting all work automatically
3. **Commit your work** - Remember to commit `uv.lock` but not `.venv`
4. **Share with team** - They can clone and run `uv sync` to get the same environment

## Tips

- ✅ Always commit `uv.lock` for reproducibility
- ✅ Use `uv add --dev` for development tools
- ✅ Run `uv sync` after pulling changes
- ✅ Use `uv run` for scripts to ensure correct environment
- ✅ Let direnv handle venv activation automatically

## Resources

- **UV Guide**: See `UV_GUIDE.md` for complete UV documentation
- **Direnv Guide**: See `DIRENV_GUIDE.md` for direnv details
- **LazyVim Extras**: See `LAZYVIM_EXTRAS.md` for Neovim customization

Happy coding! 🚀
