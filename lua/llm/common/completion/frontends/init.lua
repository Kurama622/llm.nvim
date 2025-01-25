local LOG = require("llm.common.log")
local state = require("llm.state")

local function init(opts)
  if not state.completion.frontend then
    if opts.style == "virtual_text" then
      if not opts.ignore_filetypes_dict[vim.bo.ft] then
        LOG:TRACE("llm.nvim completion style: virtual_text")
        local virtual_text = require("llm.common.completion.frontends.virtual_text")
        state.completion.frontend = virtual_text
        state.completion.frontend.opts = opts
        return virtual_text
      end
    end
    if opts.style == "blink.cmp" then
      LOG:TRACE("llm.nvim completion style: blink.cmp")
      local blink = require("llm.common.completion.frontends.blink")
      state.completion.frontend = blink
      state.completion.frontend.opts = opts
      return blink
    end
    if opts.style == "nvim-cmp" then
      if not opts.ignore_filetypes_dict[vim.bo.ft] then
        LOG:TRACE("llm.nvim completion style: nvim-cmp")
        local cmp = require("llm.common.completion.frontends.cmp")
        require("cmp").register_source("llm", cmp:new())
        state.completion.frontend = cmp
        state.completion.frontend.opts = opts
        return cmp
      end
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
