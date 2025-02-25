local LOG = require("llm.common.log")
local sess = require("llm.session")
local conf = require("llm.config")
local F = require("llm.common.api")
local M = {}

function M.handler(_, _, _, _, _, opts)
  local options = {
    is_codeblock = false,
  }
  options = vim.tbl_deep_extend("force", options, opts or {})
  F.GetAttach(options)
  F.VisMode2NorMode()
  LOG:INFO("Attach successfully!")

  if conf.session.status == -1 then
    sess.NewSession()
  end
end

return M
