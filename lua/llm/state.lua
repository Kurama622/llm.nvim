local M = {}

M.cursor = {
  role = nil,
  has_prefix = true,
  pos = 1,
}

M.llm = {
  popup = nil,
  worker = { jobs = {} },
}

M.input = {
  popup = nil,
  attach_content = "",
  lsp_ctx = {},
}

M.history = {
  popup = nil,
  index = nil,
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
  changed = {},
  filename = nil,
}

M.popwin_list = {}

M.app = {
  session = {},
}

M.completion = {
  jobs = {},
  contents = {},
  backend = nil,
  frontend = nil,
  enable = true,
  set_keymap = false,
  set_autocmd = false,
}

M.models = {
  Chat = {},
}

M.model_params = {
  "url",
  "model",
  "api_type",
  "fetch_key",
  "streaming_handler",
  "parse_handler",
  "max_tokens",
  "keep_alive",
  "temperature",
  "top_p",
  "enable_thinking",
  "thinking_budget",
  "timeout", -- for curl
  "schema",
  "functions_tbl",
}

M.summarize_suggestions = {
  --- @type nil | {start_str:string, end_str:string}
  pattern = nil,
  ctx = nil,
  prompt = nil,
  status = false,
  cnt = 0,
}

M.reason_range = {
  is_begin = false,
  is_end = false,
}

M.enabled_cmds = {}

M.lsp_context = { fname = nil, start_line = nil, end_line = nil }

return M
