local M = {}

local conf = require("llm.config")
local F = require("llm.common.func")
local streaming = require("llm.common.streaming").GetStreamingOutput

local state = require("llm.state")

function M.LLMTemplateHandler(name)
  if conf.configs.template_handler[name] ~= nil then
    conf.configs.template_handler[name](name, F, state, streaming)
  end
end

return M
