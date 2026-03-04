# Next Steps: Testing and Using Your Python Setup

## Quick Verification Checklist

### 1. Verify Nix Packages Are Installed

```bash
# Check if ruff and pyright are available
which ruff
which pyright
ruff --version
pyright --version
```

If they're not found, rebuild your Nix configuration:
```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
```

### 2. Test Neovim Configuration

Open Neovim and verify Python support:

```bash
nvim
```

In Neovim, check:
- `:Lazy` - Should show Python extras loaded
- `:LspInfo` - Should show pyright available for Python files
- `:checkhealth` - Verify LSP and other components

### 3. Create a Test Python Project

Test the full setup with a real project:

```bash
# Create a test project
mkdir ~/test-python-project
cd ~/test-python-project

# Create a Python file
cat > main.py << 'EOF'
def hello_world():
    x = 1 + 2
    y = "hello"
    return x, y

if __name__ == "__main__":
    print(hello_world())
EOF
```

### 4. Set Up Direnv (Choose One Method)

#### Option A: Traditional venv (Simple)

```bash
# Create .envrc
cat > .envrc << 'EOF'
layout python
EOF

# Allow direnv
direnv allow

# Install a test package
pip install requests
```

#### Option B: Nix devShell (Recommended)

```bash
# Create flake.nix
cat > flake.nix << 'EOF'
{
  description = "Python test project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          python311
          ruff
          pyright
        ];
        
        shellHook = ''
          if [ ! -d .venv ]; then
            python -m venv .venv
          fi
          source .venv/bin/activate
        '';
      };
    };
}
EOF

# Create .envrc
echo "use flake" > .envrc
direnv allow
```

### 5. Test in Neovim

```bash
# Open the Python file
nvim main.py
```

**Verify these work:**

1. **LSP (pyright)**:
   - Should show type hints and autocomplete
   - Try `:LspInfo` to see pyright is attached
   - Hover over variables to see type information

2. **Formatting (ruff)**:
   - Make the code unformatted: `x=1+2` instead of `x = 1 + 2`
   - Format with `<leader>cf` (or `:Format`)
   - Should auto-format

3. **Linting (ruff)**:
   - Add an unused import: `import os` at the top
   - Should show a warning/error
   - Check with `:Lint`

4. **Environment Detection**:
   - `:echo $VIRTUAL_ENV` should show your venv path
   - `:echo system('which python')` should show venv Python

### 6. Test Direnv Auto-Switching

```bash
# In your project directory
cd ~/test-python-project
# Direnv should automatically activate (check prompt or run: echo $VIRTUAL_ENV)

# Leave the directory
cd ~
# Environment should unload

# Return
cd ~/test-python-project
# Environment should load again automatically
```

## Common Issues and Fixes

### Issue: Ruff/Pyright Not Found

**Solution:**
```bash
# Rebuild Nix configuration
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro

# Verify in new shell
which ruff
which pyright
```

### Issue: LSP Not Starting in Neovim

**Check:**
1. `:LspInfo` - See if pyright is listed
2. `:checkhealth lsp` - Check for errors
3. Verify Python file is detected: `:set filetype?` should show `filetype=python`

**Fix:**
```bash
# Restart Neovim
# Or manually start LSP: :LspStart pyright
```

### Issue: Direnv Not Loading

**Check:**
```bash
# Verify direnv hook is in shell
echo $DIRENV_SHELL

# Check if .envrc is allowed
direnv status

# Allow if needed
direnv allow
```

**Fix:**
If direnv hook is missing, add to `~/.zshrc`:
```bash
eval "$(direnv hook zsh)"
```

### Issue: Formatter Not Working

**Check:**
```lua
-- In Neovim
:lua print(vim.inspect(require("conform").formatters_by_ft.python))
```

Should show `{ "ruff_format" }`

**Fix:**
- Verify ruff is in PATH: `which ruff`
- Check Neovim config loaded: `:Lazy` should show no errors

## Real Project Setup

### For a New Python Project

1. **Create project directory**
   ```bash
   mkdir my-project
   cd my-project
   ```

2. **Choose your method:**
   - **Simple**: Use `layout python` in `.envrc`
   - **Nix**: Create `flake.nix` and use `use flake`

3. **Create `.envrc`**
   ```bash
   # Simple
   echo "layout python" > .envrc
   direnv allow
   
   # Or Nix
   # (create flake.nix first, then)
   echo "use flake" > .envrc
   direnv allow
   ```

4. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   # or
   poetry install
   ```

5. **Open in Neovim**
   ```bash
   nvim .
   ```

6. **Verify everything works:**
   - LSP shows type hints
   - Formatting works (`<leader>cf`)
   - Linting shows errors
   - Environment is active (`echo $VIRTUAL_ENV`)

## Recommended Workflow

### Daily Development

1. **Enter project directory**
   - Direnv automatically loads environment
   - Neovim inherits the environment

2. **Open Neovim**
   ```bash
   nvim .
   ```

3. **Work with Python files**
   - LSP provides autocomplete and type hints
   - Format on save (if configured) or manually with `<leader>cf`
   - Linting shows inline errors

4. **Leave directory**
   - Direnv automatically unloads environment

### Adding New Dependencies

**With venv:**
```bash
pip install new-package
pip freeze > requirements.txt
```

**With Nix:**
```nix
# Add to flake.nix packages
python311Packages.new-package
```

## Next Enhancements (Optional)

### 1. Format on Save

Add to your Neovim config:
```lua
-- In lua/config/autocmds.lua or plugins/example.lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    require("conform").format({ async = false })
  end,
})
```

### 2. Auto-install Dependencies

Add to Nix shellHook:
```nix
shellHook = ''
  source .venv/bin/activate
  if [ -f requirements.txt ] && [ ! -f .venv/.direnv-installed ]; then
    pip install -r requirements.txt
    touch .venv/.direnv-installed
  fi
'';
```

### 3. Project-Specific Neovim Settings

Create `.nvim.lua` in project root:
```lua
-- Project-specific settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
```

### 4. Add More Languages

Follow the same pattern for other languages:
- TypeScript: Already configured
- Go: Add `lang.go` extra
- Rust: Add `lang.rust` extra

## Summary

✅ **Completed:**
- Python LSP (pyright) configured
- Ruff formatter and linter configured
- Direnv setup documented
- Nix packages added

🎯 **Next Actions:**
1. Test the setup with a real project
2. Choose your direnv method (venv or Nix)
3. Verify LSP, formatting, and linting work
4. Start using it in your projects!

## Resources

- **LazyVim Extras**: See `LAZYVIM_EXTRAS.md`
- **Direnv Guide**: See `DIRENV_GUIDE.md`
- **LazyVim Docs**: https://www.lazyvim.org
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
