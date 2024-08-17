local M = {}
-- local conf = require("llm.config")

M.llm = {
  popup = nil,
  bufnr = nil,
  winid = nil,
  job = nil,
}

M.input = {
  popup = nil,
  bufnr = nil,
  winid = nil,
}

M.popwin = nil
return M
