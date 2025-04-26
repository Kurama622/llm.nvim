local M = {}

local conf = require("llm.config")
local F = require("llm.common.api")
local streaming = require("llm.common.io.streaming").GetStreamingOutput

local state = require("llm.state")

function M.LLMAppHandler(name)
  if conf.configs.app_handler[name] ~= nil then
    local tool = {
      handler = nil,
      prompt = nil,
      --- @type nil | table
      opts = nil,
    }

    tool = vim.tbl_deep_extend("force", tool, conf.configs.app_handler[name] or {})
    if tool.opts.models then
      require("llm.common.layout").models_preview(tool.opts, name, function(choice, idx)
        if not choice then
          return
        end
        tool.opts.url, tool.opts.model, tool.opts.api_type, tool.opts.max_tokens, tool.opts.fetch_key =
          tool.opts.models[idx].url,
          tool.opts.models[idx].model,
          tool.opts.models[idx].api_type,
          tool.opts.models[idx].max_tokens,
          tool.opts.models[idx].fetch_key

        tool.handler(name, F, state, streaming, tool.prompt, tool.opts)
      end)
    else
      tool.handler(name, F, state, streaming, tool.prompt, tool.opts)
    end
  end
end

function M.auto_trigger()
  for name in pairs(conf.configs.app_handler) do
    if conf.configs.app_handler[name].opts and conf.configs.app_handler[name].opts.auto_trigger ~= nil then
      M.LLMAppHandler(name)
    end
  end
end
return M
