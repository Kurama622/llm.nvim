local M = {}

function M.setup(opts)
  if not opts then
    opts = { keys = {} }
  end
  require("llm.config").setup(opts)
  vim.api.nvim_exec_autocmds("User", { pattern = "AutoTrigger" })
end

return M
