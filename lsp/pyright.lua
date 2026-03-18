return {
  settings = {
    pyright = { useLibraryCodeForTypes = false },
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = false,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = false,
        exclude = {
          "**/node_modules", "**/__pycache__", "**/.*",
          "**/venv", "**/.venv", "**/build", "**/dist",
        },
      },
    },
  },
}
