local M = {}

function M.setup(opts)
  if not opts then
    opts = { keys = {} }
  end
  require("llm.config").setup(opts)
  require("llm.app").auto_trigger()
end

return M
