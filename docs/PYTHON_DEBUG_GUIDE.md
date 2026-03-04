# Python Debugging Guide for Neovim (LazyVim)

This guide explains how to use the Python debugger (DAP) in Neovim with LazyVim.

## Setup Complete ✓

The DAP configuration has been set up in your Neovim config. You just need to install `debugpy`.

## Prerequisites

1. **Install debugpy** in your project virtual environment (Recommended):
   ```bash
   # For system Python (using Nix Python)
   pip install debugpy
   
   # Or in your virtual environment (recommended)
   source .venv/bin/activate  # or your venv path
   pip install debugpy
   
   # Or using uv (if you use uv for package management)
   uv pip install debugpy
   
   # Verify installation
   python3 -c "import debugpy; print('debugpy installed successfully')"
   ```

   **Note**: The debugger will automatically detect and use (in order):
   1. Virtual environment Python if `$VIRTUAL_ENV` is set (project venv) - **Recommended**
   2. `.venv/bin/python` in your project directory (local venv)
   3. System/Nix Python (`python3`) as fallback

   **For Nix users**: Install debugpy in your project venvs (standard practice). The DAP configuration automatically detects venv Python, which works seamlessly with Nix + direnv + uv workflows.

2. **Restart Neovim** after installing debugpy to ensure it's detected

2. **Ensure DAP extras are enabled** (already configured in your setup):
   - `dap.core` - Base DAP infrastructure
   - `lang.python` - Python DAP support

## Quick Start

### 1. Set Breakpoints

- **Toggle breakpoint**: `<leader>db` (default: `<Space>db`)
- **Conditional breakpoint**: `<leader>dB` (set breakpoint with condition)
- **Logpoint**: `<leader>dL` (log message instead of breaking)

### 2. Start Debugging

When you press `<leader>dc`, you'll see a configuration selector. Choose one:

#### Available Configurations:

1. **Python: Current File** (Recommended for most cases)
   - Runs the currently open Python file
   - No arguments needed
   - Use this for simple scripts

2. **Python: File with Args**
   - Runs the current file with command-line arguments
   - Prompts you to enter arguments (space-separated)
   - Example: Enter `--verbose --output results.txt` when prompted

3. **Python: Module**
   - Runs a Python module (like `python -m pytest`)
   - Prompts you to enter the module name
   - Example: Enter `pytest` or `mymodule.main`

4. **Python: Attach**
   - Attaches to a running Python process
   - Prompts for host (default: localhost) and port (default: 5678)
   - Use this for remote debugging

5. **Python: Pytest**
   - Runs pytest on the current test file
   - Automatically configured for test debugging

#### How to Use:

1. Open a Python file
2. Set breakpoints with `<leader>db`
3. Press `<leader>dc`
4. Select a configuration from the list
5. If prompted, enter arguments/module name/port
6. Debugging starts!

- **Run to cursor**: `<leader>dC` - Run until cursor position
- **Step over**: `<leader>do` - Step over current line
- **Step into**: `<leader>di` - Step into function
- **Step out**: `<leader>dO` - Step out of current function

### 3. Debugging UI

- **Toggle REPL**: `<leader>dr` - Open/close debug REPL
- **Toggle UI**: `<leader>du` - Toggle debug UI
- **Hover variables**: Hover over variables to see their values
- **Watch expressions**: Add expressions to watch in the debug UI

### 4. Stop Debugging

- **Pause**: `<leader>dp` - Pause execution
- **Terminate**: `<leader>dt` - Stop debugging session
- **Restart**: `<leader>dR` - Restart debugging session

## Example: Debugging a Python File

### Create a test file (`test_debug.py`):

```python
def calculate_sum(a, b):
    result = a + b  # Set breakpoint here with <leader>db
    return result

def main():
    x = 10
    y = 20
    total = calculate_sum(x, y)  # Set breakpoint here
    print(f"Sum: {total}")

if __name__ == "__main__":
    main()
```

### Debugging Steps:

1. **Open the file** in Neovim
2. **Set breakpoints**:
   - Move cursor to line 2 (`result = a + b`)
   - Press `<leader>db` to set a breakpoint
   - Move to line 8 (`total = calculate_sum(x, y)`)
   - Press `<leader>db` to set another breakpoint
3. **Start debugging**:
   - Press `<leader>dc` to start debugging
   - Select "Python File" when prompted
4. **Navigate**:
   - Use `<leader>do` to step over
   - Use `<leader>di` to step into functions
   - Use `<leader>dO` to step out
5. **Inspect variables**:
   - Hover over variables to see values
   - Use `<leader>du` to open debug UI for watch expressions
6. **Continue**: Press `<leader>dc` to continue to next breakpoint

## Configuration

The debugger is configured to:
- Use virtual environment Python if available (`$VIRTUAL_ENV/bin/python`)
- Fall back to system Python (`python3` or `python`)
- Support pytest for test debugging

## Debug Configurations

You can create `.vscode/launch.json` or `.nvim-dap.json` for custom debug configurations:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "name": "Python: Module",
      "type": "python",
      "request": "launch",
      "module": "mymodule",
      "console": "integratedTerminal"
    }
  ]
}
```

## Troubleshooting

### Debugger not starting

1. **Check debugpy installation**:
   ```bash
   python3 -c "import debugpy; print(debugpy.__file__)"
   ```

2. **Check Python path**:
   - The debugger uses `$VIRTUAL_ENV/bin/python` if venv is active
   - Otherwise uses system `python3`

3. **Check DAP logs**:
   - Run `:DapLog` to see debug adapter logs

### Breakpoints not working

- Ensure you're using a Python file (`.py` extension)
- Make sure the file is saved
- Check that debugpy is installed in the Python environment being used

### Virtual environment not detected

- Activate your venv before starting Neovim:
  ```bash
  source .venv/bin/activate
  nvim
  ```
- Or set `VIRTUAL_ENV` environment variable

## Advanced Usage

### Debugging Tests

1. Set breakpoints in your test file
2. Start debugging with `<leader>dc`
3. Select "Python: Pytest" configuration
4. The debugger will run pytest and stop at breakpoints

### Remote Debugging

To debug a remote Python process, you can attach:

```json
{
  "name": "Python: Attach",
  "type": "python",
  "request": "attach",
  "connect": {
    "host": "localhost",
    "port": 5678
  }
}
```

Then in your Python code:
```python
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()  # Optional: wait for debugger to attach
```

## Keymaps Reference

| Keymap | Action |
|--------|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dL` | Logpoint |
| `<leader>dc` | Start/Continue |
| `<leader>dC` | Run to cursor |
| `<leader>do` | Step over |
| `<leader>di` | Step into |
| `<leader>dO` | Step out |
| `<leader>dp` | Pause |
| `<leader>dt` | Terminate |
| `<leader>dR` | Restart |
| `<leader>dr` | Toggle REPL |
| `<leader>du` | Toggle UI |

## Tips

1. **Use watch expressions** to monitor variable values during debugging
2. **Set conditional breakpoints** to break only when certain conditions are met
3. **Use logpoints** to log values without stopping execution
4. **Debug UI** provides a visual interface for breakpoints, variables, and call stack
5. **REPL** allows you to execute Python code in the current debug context
