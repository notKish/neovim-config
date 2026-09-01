-- olimorris/codecompanion.nvim — chat, inline AI, agents, MCP (:CodeCompanion*)
--
-- Provider selection (pick one):
--   1. vim.g.codecompanion.adapter = "deepseek"   — CodeCompanion-only override
--   2. vim.g.ai_completion.provider = "deepseek"  — shared with <C-a> completion (lua/plugins/ai.lua)
--   3. Auto: first provider in vim.g.ai_completion.providers with a set API key
--
-- Add providers under vim.g.ai_completion.providers (same table as ai.lua):
--   deepseek = {
--     api = "openai",
--     env_key = "DEEPSEEK_API_KEY",
--     model = "deepseek-chat",
--     endpoint = "https://api.deepseek.com/v1/chat/completions",
--   }
--
-- Per-interaction overrides:
--   vim.g.codecompanion = {
--     adapter = "anthropic",
--     interactions = { inline = { adapter = "openai" } },
--   }
--
-- At runtime, switch adapter in chat: :CodeCompanionChat adapter=openai
local ai = require("plugins.ai")

local function active_adapter(config)
  local cc = vim.g.codecompanion or {}
  return cc.adapter or config.provider
end

local function build_http_adapter(name, spec)
  local base = spec.api == "anthropic" and "anthropic" or "openai"
  return function()
    local opts = {
      name = name,
      formatted_name = name:sub(1, 1):upper() .. name:sub(2),
      url = spec.endpoint,
      env = {
        api_key = spec.env_key,
      },
      schema = {
        model = {
          default = spec.model,
          choices = {
            [spec.model] = {},
          },
        },
      },
    }
    if spec.api == "anthropic" and spec.anthropic_version then
      opts.headers = {
        ["anthropic-version"] = spec.anthropic_version,
      }
    end
    return require("codecompanion.adapters").extend(base, opts)
  end
end

local function build_http_adapters(providers)
  local http = {}
  for name, spec in pairs(providers) do
    if type(spec) == "table" and spec.api and spec.endpoint and spec.env_key and spec.model then
      http[name] = build_http_adapter(name, spec)
    end
  end
  return http
end

local function interaction_adapters(config, default)
  local cc = vim.g.codecompanion or {}
  local user = cc.interactions or {}
  return {
    chat = (user.chat and user.chat.adapter) or default,
    inline = (user.inline and user.inline.adapter) or default,
    cmd = (user.cmd and user.cmd.adapter) or default,
  }
end

local config = ai.resolve_config()
local adapter = active_adapter(config)
local interactions = interaction_adapters(config, adapter)

local ok, err = pcall(function()
  require("codecompanion").setup({
    adapters = {
      http = build_http_adapters(config.providers),
    },
    interactions = {
      chat = { adapter = interactions.chat },
      inline = { adapter = interactions.inline },
      cmd = { adapter = interactions.cmd },
    },
  })
end)

if not ok then
  vim.notify("codecompanion.nvim failed to load: " .. tostring(err), vim.log.levels.ERROR)
end
