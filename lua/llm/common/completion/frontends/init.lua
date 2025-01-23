local LOG = require("llm.common.log")
local state = require("llm.state")

local function init(opts)
  if not state.completion.frontend then
    if opts.style == "virtual_text" then
      LOG:TRACE("llm.nvim completion style: virtual_text")
      local virtual_text = require("llm.common.completion.frontends.virtual_text")
      state.completion.frontend = virtual_text
      return virtual_text
    end
  else
    return state.completion.frontend
  end
end

return setmetatable({}, {
  __call = function(_, opts)
    return init(opts)
  end,
})
