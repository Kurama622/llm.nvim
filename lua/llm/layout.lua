local M = {}

M.cursor = {
  role = nil,
  has_prefix = true,
  pos = 1,
}

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
