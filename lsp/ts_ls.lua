return {
  settings = {
    typescript = {
      preferences = { includePackageJsonAutoImports = "off" },
      inlayHints = {
        parameterNames = { enabled = "none" },
        variableTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = false },
        functionLikeReturnTypes = { enabled = false },
      },
    },
    javascript = {
      preferences = { includePackageJsonAutoImports = "off" },
    },
  },
}
