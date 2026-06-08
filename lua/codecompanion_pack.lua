-- olimorris/codecompanion.nvim — chat, inline AI, agents, MCP (:CodeCompanion*)
-- Uses built-in OpenAI / Anthropic adapters. Override with vim.g.codecompanion.adapter
-- or vim.g.ai_completion.provider (see lua/ai.lua).
local function default_adapter()
  local cc = vim.g.codecompanion or {}
  if cc.adapter then
    return cc.adapter
  end

  local provider = (vim.g.ai_completion or {}).provider
  if provider == "openai" or provider == "anthropic" then
    return provider
  end

  local openai_key = vim.env.OPENAI_API_KEY
  local anthropic_key = vim.env.ANTHROPIC_API_KEY
  if openai_key and openai_key ~= "" and (not anthropic_key or anthropic_key == "") then
    return "openai"
  end
  return "anthropic"
end

local adapter = default_adapter()

local ok, err = pcall(function()
  require("codecompanion").setup({
    interactions = {
      chat = { adapter = adapter },
      inline = { adapter = adapter },
      cmd = { adapter = adapter },
    },
  })
end)

if not ok then
  vim.notify("codecompanion.nvim failed to load: " .. tostring(err), vim.log.levels.ERROR)
end
