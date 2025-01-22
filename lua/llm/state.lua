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
  worker = { job = nil },
}

M.input = {
  popup = nil,
  bufnr = nil,
  winid = nil,
}

M.history = {
  popup = nil,
  list = nil,
  foucs_item = nil,
}

M.other = {
  popup = nil,
}

M.layout = {
  popup = nil,
}

M.session = {
  filename = nil,
}

M.popwin = nil

M.app = {
  session = {},
}

M.completion = {
  jobs = {},
  contents = {},
  enable = true,
  set_keymap = false,
  set_autocmd = false,
}
return M
