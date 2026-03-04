# UV + Direnv Integration Template

## Quick Setup

Copy this `.envrc` template for your Python projects:

### For UV Projects (Recommended)

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

### Simpler Version (Always use UV)

If you always use UV for your projects:

```bash
# .envrc
layout python3
export UV_PROJECT_ENVIRONMENT=.venv
```

## Usage

1. **Create project:**
   ```bash
   mkdir my-project && cd my-project
   ```

2. **Copy .envrc:**
   ```bash
   # Copy the template above into .envrc
   cat > .envrc << 'EOF'
   # ... paste template ...
   EOF
   ```

3. **Allow direnv:**
   ```bash
   direnv allow
   ```

4. **Initialize UV project:**
   ```bash
   uv init
   uv add requests
   uv sync
   ```

5. **Start coding!**
   - Direnv automatically activates venv when you enter the directory
   - UV commands work seamlessly
   - Neovim will use the correct Python environment

## What This Does

- ✅ Automatically creates/activates `.venv` when entering directory
- ✅ UV uses the correct virtual environment
- ✅ Works with both UV projects (`pyproject.toml`) and regular Python projects
- ✅ Seamless integration with Neovim LSP (pyright)
- ✅ All tools (ruff, pyright) available from global Nix packages

## Testing

After setting up, verify everything works:

```bash
# Check venv is active
which python
# Should show: /path/to/project/.venv/bin/python

# Check UV uses the venv
uv pip list
# Should show packages in .venv

# Check environment variable
echo $UV_PROJECT_ENVIRONMENT
# Should show: .venv
```

## Troubleshooting

### Issue: UV not found

**Solution:**
```bash
# Rebuild Nix
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
```

### Issue: Direnv not activating

**Solution:**
```bash
# Check direnv is allowed
direnv allow

# Check direnv hook is in shell
echo $DIRENV_SHELL

# If missing, add to ~/.zshrc:
eval "$(direnv hook zsh)"
```

### Issue: UV not using .venv

**Solution:**
```bash
# Verify environment variable is set
echo $UV_PROJECT_ENVIRONMENT

# Manually set if needed
export UV_PROJECT_ENVIRONMENT=.venv
```
