# Direnv Guide for Python and Other Languages

## Overview

Direnv automatically loads and unloads environment variables when you enter or leave a directory. This is perfect for managing project-specific Python virtual environments, Node.js versions, Go paths, and more.

## Prerequisites

Direnv is already configured in your Nix setup with **nix-direnv** enabled. Verify it's working:

```bash
which direnv
direnv version
```

### What nix-direnv Provides

**nix-direnv** (enabled in your flake) provides:
- ✅ **Faster direnv loading** when using Nix (caching mechanism)
- ✅ **Support for `use flake`** and `use nix` commands
- ✅ **Automatic Nix shell activation** when entering directories

**What it does NOT do automatically:**
- ❌ Does NOT create Python virtual environments automatically
- ❌ Does NOT activate Python venvs (you still need `layout python` or manual activation)

**For Python, you have two approaches:**
1. **Pure Nix approach**: Use Python packages directly from Nix (no venv needed)
2. **Hybrid approach**: Use Nix for tools (ruff, pyright) + traditional venv for Python packages

## Your Current Setup

You have **nix-direnv** enabled in your Nix flake, which means:
- ✅ Direnv is installed and configured
- ✅ nix-direnv caching is enabled (faster `use flake` commands)
- ✅ Shell hook should be automatically configured via Home Manager

**To verify everything works:**
```bash
# Check direnv is in PATH
which direnv

# Check nix-direnv is working (should show faster loading)
cd /tmp
mkdir test-direnv && cd test-direnv
echo "use flake" > .envrc
# This should work if you have a flake.nix, or show an error if not
direnv allow
```

## Basic Setup

### 1. Allow Direnv in Your Shell

Direnv needs to hook into your shell. Add this to your `~/.zshrc` (if not already there):

```bash
eval "$(direnv hook zsh)"
```

Since you're using Home Manager, this should already be configured via your Nix flake.

### 2. Create `.envrc` Files

Create a `.envrc` file in your project directory to define the environment.

## Python Virtual Environments

### Method 1: Using Python venv (Traditional)

Create a `.envrc` in your Python project:

```bash
# .envrc
source_env_if_exists .venv/bin/activate
# or
layout python
```

**Using `layout python`:**
- Automatically creates a `.venv` directory if it doesn't exist
- Activates the virtual environment
- Sets `VIRTUAL_ENV` and updates `PATH`

**Example workflow:**
```bash
cd my-python-project
# Create .envrc
echo "layout python" > .envrc
direnv allow

# Direnv will automatically:
# 1. Create .venv if it doesn't exist
# 2. Activate the virtual environment
# 3. Update PATH to use venv's Python
```

### Method 2: Using Nix devShell (Recommended for Nix Users)

For projects using Nix flakes, **nix-direnv** makes this seamless:

```bash
# .envrc
use flake
```

This will:
- Load the Nix development shell defined in `flake.nix` (via nix-direnv caching)
- Make all packages from `devShells.default` available
- Automatically switch when entering the directory

**Option 2a: Pure Nix (No venv needed)**

Use Python packages directly from Nix. Great for tools, but Python packages must be in Nix:

```nix
# flake.nix
{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      python311
      python311Packages.requests
      python311Packages.flask
      ruff
      pyright
    ];
  };
}
```

**Option 2b: Nix + venv Hybrid (Recommended)**

Use Nix for development tools, venv for Python packages:

```nix
# flake.nix
{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      python311
      ruff
      pyright
      # Python packages go in requirements.txt, installed in venv
    ];
    
    shellHook = ''
      # Create venv if it doesn't exist
      if [ ! -d .venv ]; then
        python -m venv .venv
      fi
      source .venv/bin/activate
      
      # Install dependencies if requirements.txt exists
      if [ -f requirements.txt ] && [ ! -f .venv/.direnv-installed ]; then
        pip install -r requirements.txt
        touch .venv/.direnv-installed
      fi
    '';
  };
}
```

Then in `.envrc`:
```bash
use flake
# The shellHook above handles venv creation/activation
```

### Method 3: Using Poetry

```bash
# .envrc
layout poetry
```

This activates Poetry's virtual environment automatically.

### Method 4: Using Pipenv

```bash
# .envrc
layout pipenv
```

### Method 5: Custom Python Path

```bash
# .envrc
export PYTHONPATH="${PWD}/src:${PYTHONPATH}"
source_env_if_exists .venv/bin/activate
```

## Node.js / JavaScript

### Using NVM

```bash
# .envrc
use nodejs 18.17.0
# or
export NODE_VERSION=18.17.0
```

### Using Nix

```bash
# .envrc
use flake
```

With Node.js in your devShell:
```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    nodejs_20
    pnpm
  ];
};
```

## Go

### Using Nix

```bash
# .envrc
use flake
```

With Go in devShell:
```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    go
    gopls
  ];
  
  # Set GOPATH
  shellHook = ''
    export GOPATH="${PWD}/.go"
    export PATH="$GOPATH/bin:$PATH"
  '';
};
```

### Traditional Go Setup

```bash
# .envrc
export GOPATH="${PWD}/.go"
export PATH="$GOPATH/bin:${PATH}"
```

## Rust

### Using Nix

```bash
# .envrc
use flake
```

With Rust in devShell:
```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    rustc
    cargo
    rust-analyzer
  ];
};
```

## Multi-Language Projects

### Combining Multiple Tools

```bash
# .envrc
# Python
layout python

# Node.js
export NODE_VERSION=20.10.0

# Custom paths
export PATH="${PWD}/bin:${PATH}"
export PYTHONPATH="${PWD}/src:${PYTHONPATH}"
```

### Using Nix for Everything

```bash
# .envrc
use flake
```

Then define everything in `flake.nix`:
```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    python311
    ruff
    pyright
    nodejs_20
    pnpm
    go
    rustc
    cargo
  ];
};
```

## Advanced Usage

### Loading Secrets

```bash
# .envrc
# Load API keys from a file (make sure it's in .gitignore!)
dotenv .env.local

# Or load specific variables
export API_KEY="$(cat .secrets/api_key)"
```

### Conditional Loading

```bash
# .envrc
if [[ -f .venv/bin/activate ]]; then
  source .venv/bin/activate
else
  layout python
fi
```

### Project-Specific Environment Variables

```bash
# .envrc
export PROJECT_NAME="my-project"
export DEBUG=true
export DATABASE_URL="postgresql://localhost/mydb"
```

### Loading Parent Directory Config

```bash
# .envrc in subdirectory
source_env ../.envrc
```

## Integration with Neovim

### Automatic Environment Switching

When you open Neovim in a directory with `.envrc`:
1. Direnv loads the environment
2. Neovim inherits the environment variables
3. LSP servers (like pyright) automatically use the correct Python interpreter
4. Formatters and linters use tools from the activated environment

### Verifying Environment in Neovim

```vim
" Check Python path
:echo $VIRTUAL_ENV
:echo system('which python')

" Check if direnv loaded
:echo $DIRENV_DIR
```

### Troubleshooting LSP in Neovim

If pyright or other LSPs don't detect the right environment:

1. **Restart Neovim** after `direnv allow`
2. **Check Python path**: `:echo system('which python')`
3. **Manually set in pyrightconfig.json**:
   ```json
   {
     "venvPath": ".",
     "venv": ".venv"
   }
   ```

## Common Patterns

### Python Project Template

```bash
# .envrc
layout python

# Install dependencies automatically
if [[ ! -f .venv/.direnv-installed ]]; then
  pip install -r requirements.txt
  touch .venv/.direnv-installed
fi
```

### Nix + Python Hybrid

```bash
# .envrc
use flake

# Use Nix Python but create local venv for pip packages
if [[ ! -d .venv ]]; then
  python -m venv .venv
fi
source .venv/bin/activate
```

### Development vs Production

```bash
# .envrc
if [[ "$ENV" == "development" ]]; then
  export DEBUG=true
  export LOG_LEVEL=debug
else
  export DEBUG=false
  export LOG_LEVEL=info
fi
```

## Troubleshooting

### Direnv Not Loading

1. **Check hook is installed**: `echo $DIRENV_SHELL`
2. **Allow the directory**: `direnv allow`
3. **Check for errors**: `direnv status`

### Environment Not Updating

1. **Force reload**: `direnv reload`
2. **Check .envrc syntax**: `direnv allow` will show errors
3. **Restart terminal/Neovim**

### Python Not Found

1. **Check PATH**: `echo $PATH`
2. **Verify venv exists**: `ls -la .venv/bin/python`
3. **Check .envrc**: Make sure `layout python` or `source` is correct

### Nix Flake Issues

1. **Check flake.nix syntax**: `nix flake check`
2. **Update flake**: `nix flake update`
3. **Rebuild**: `direnv reload`

## Best Practices

1. **Always `.gitignore` sensitive files**:
   ```
   .envrc.local
   .secrets/
   .env
   ```

2. **Document your setup**: Add comments in `.envrc`

3. **Use Nix when possible**: More reproducible than traditional venv

4. **Test in clean environment**: `direnv allow` should work on fresh clone

5. **Version control `.envrc`**: It's safe to commit (no secrets)

## Example Project Structure

```
my-project/
├── .envrc              # Direnv config (committed)
├── .envrc.local        # Local overrides (gitignored)
├── .gitignore
├── flake.nix          # Nix devShell (optional)
├── requirements.txt    # Python deps
├── .venv/             # Virtual env (gitignored)
└── src/
    └── main.py
```

## Quick Reference

```bash
# Commands
direnv allow          # Allow .envrc in current directory
direnv deny           # Block .envrc
direnv reload          # Force reload
direnv status          # Show current status
direnv version         # Show version

# Common .envrc patterns
layout python          # Create/activate Python venv
layout nodejs          # Use specific Node version
use flake              # Use Nix flake devShell
dotenv .env            # Load .env file
source_env ../.envrc   # Load parent .envrc
```

## Resources

- **Direnv Docs**: https://direnv.net/
- **Nix Direnv**: https://github.com/nix-community/nix-direnv
- **LazyVim Python**: See `LAZYVIM_EXTRAS.md` for Neovim integration
