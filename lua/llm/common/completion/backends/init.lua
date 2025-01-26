local LOG = require("llm.common.log")
local state = require("llm.state")

local function init(opts)
  if not state.completion.backend then
    if opts.api_type == "ollama" then
      local ollama = require("llm.common.completion.backends.ollama")
      state.completion.backend = ollama
      LOG:TRACE("llm.nvim completion provider: ollama")
      return ollama
    elseif opts.api_type == "deepseek" then
      local deepseek = require("llm.common.completion.backends.deepseek")
      state.completion.backend = deepseek
      LOG:TRACE("llm.nvim completion provider: deepseek")
      return deepseek
    end
  else
    return state.completion.backend
  end
end

return setmetatable({}, {
  __call = function(_, opts)
    return init(opts)
  end,
})
