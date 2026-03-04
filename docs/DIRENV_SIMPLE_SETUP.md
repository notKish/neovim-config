# Simple Direnv Setup for Python Projects

## Quick Answer: No, You Don't Need flake.nix for Every Project!

You have **three options** depending on your needs:

## Option 1: Simple venv (No Nix, Fastest Setup)

**Best for:** Quick projects, prototyping, when you don't need specific tool versions

```bash
# .envrc
layout python3
```

**Requirements:**
- Python 3 must be in PATH (usually `/usr/bin/python3` on macOS)
- Works with system Python or any Python in PATH

**Pros:**
- ✅ Simplest setup (one line)
- ✅ No Nix knowledge needed
- ✅ Fast to set up

**Cons:**
- ❌ Uses system Python (may not be latest)
- ❌ Doesn't provide ruff/pyright automatically
- ❌ Less reproducible

## Option 2: Nix Python + venv (Hybrid, Recommended)

**Best for:** Most projects - get tools from Nix, packages from venv

Add Python to your **global Nix config** once, then use simple `.envrc`:

### Step 1: Add Python to Global Nix Config (One Time)

Edit `~/.config/nix/flake.nix` and add Python to `home.packages`:

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  python311  # Add this
  ruff       # Already there
  pyright    # Already there
];
```

Then rebuild:
```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
```

### Step 2: Use Simple .envrc in Each Project

```bash
# .envrc
layout python3
```

Now Python, ruff, and pyright are available globally, and each project gets its own venv.

**Pros:**
- ✅ Simple `.envrc` (one line per project)
- ✅ Consistent Python version across projects
- ✅ Tools (ruff, pyright) available everywhere
- ✅ Project-specific packages in venv

**Cons:**
- ❌ Requires one-time Nix config update

## Option 3: Per-Project flake.nix (Most Control)

**Best for:** Projects needing specific Python versions or complex dependencies

```bash
# .envrc
use flake
```

With `flake.nix` in project directory.

**Pros:**
- ✅ Complete control over Python version
- ✅ Reproducible environment
- ✅ Can pin specific package versions

**Cons:**
- ❌ More setup per project
- ❌ Need to understand Nix

## Recommended Approach: Option 2

Here's the complete setup:

### 1. Update Global Nix Config (One Time)

```nix
# In ~/.config/nix/flake.nix, add python311 to home.packages
home.packages = with pkgs; [
  # ... your existing packages ...
  python311  # Add this line
  ruff       # Already there
  pyright    # Already there
];
```

Rebuild:
```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake ~/.config/nix#ganeshs-MacBook-Pro
```

### 2. Create Simple .envrc Template

Create a template you can copy:

```bash
# ~/.envrc.template
layout python3
```

### 3. Use in Any Project

```bash
cd my-new-project
cp ~/.envrc.template .envrc
direnv allow
pip install -r requirements.txt  # or whatever you need
```

That's it! Python, ruff, and pyright are available, and you have a project-specific venv.

## Comparison Table

| Method | Setup Time | Reproducibility | Tool Availability | Best For |
|--------|-----------|-----------------|-------------------|----------|
| `layout python3` | ⚡ Instant | ⭐ Low | System only | Quick scripts |
| Nix global + `layout python3` | 🕐 One-time | ⭐⭐ Medium | All tools | Most projects |
| Per-project `flake.nix` | 🕐 Per project | ⭐⭐⭐ High | Custom per project | Production apps |

## Quick Start Commands

### For New Project (Option 2 - Recommended)

```bash
# Create project
mkdir my-project && cd my-project

# Create .envrc
echo "layout python3" > .envrc
direnv allow

# Install packages
pip install requests flask  # or whatever
pip freeze > requirements.txt
```

### For New Project (Option 3 - Full Control)

```bash
# Create project
mkdir my-project && cd my-project

# Copy flake template (see below)
cp ~/flake-template.nix flake.nix

# Edit flake.nix if needed (Python version, packages)

# Create .envrc
echo "use flake" > .envrc
direnv allow
```

## Reusable flake.nix Template

If you do want to use flake.nix for some projects, here's a template you can copy:

```nix
{
  description = "Python project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python311  # Change version if needed
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
```

Save as `~/flake-template.nix` and copy when needed.

## My Recommendation

**Use Option 2** (Nix global + simple .envrc):
1. Add `python311` to your global Nix config once
2. Use `layout python3` in `.envrc` for each project
3. Only use `flake.nix` for projects that need:
   - Specific Python versions (3.10, 3.12, etc.)
   - Complex Nix-only dependencies
   - Maximum reproducibility

This gives you the best balance of simplicity and functionality!
