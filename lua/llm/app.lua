local M = {}

local conf = require("llm.config")
local F = require("llm.common.api")
local streaming = require("llm.common.streaming").GetStreamingOutput

local state = require("llm.state")

function M.LLMAppHandler(name)
  if conf.configs.app_handler[name] ~= nil then
    local tool = {
      handler = nil,
      prompt = nil,
      opts = nil,
    }

    tool = vim.tbl_deep_extend("force", tool, conf.configs.app_handler[name] or {})
    tool.handler(name, F, state, streaming, tool.prompt, tool.opts)
  end
end

function M.auto_trigger()
  for name in pairs(conf.configs.app_handler) do
    if conf.configs.app_handler[name].opts and conf.configs.app_handler[name].opts.auto_trigger then
      M.LLMAppHandler(name)
    end
  end
end
return M
