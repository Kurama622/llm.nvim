local M = {}

local conf = require("llm.config")
local F = require("llm.common.func")
local streaming = require("llm.common.streaming").GetStreamingOutput

local state = require("llm.state")

function M.LLMAppHandler(name)
  if conf.configs.app_handler[name] ~= nil then
    conf.configs.app_handler[name](name, F, state, streaming)
  end
end

return M
