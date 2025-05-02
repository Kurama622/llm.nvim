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
  attach_content = nil,
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
  filename = nil,
}

M.popwin = nil

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

M.models = {}

M.model_params = {
  "url",
  "model",
  "api_type",
  "fetch_key",
  "streaming_handler",
  "parse_handler",
  "max_tokens",
  "keep_alive",
  "temperatrue",
  "top_p",
  "enable_thinking",
  "thinking_budget",
}

M.summarize_suggestions = {
  --- @type nil | {start_str:string, end_str:string}
  pattern = nil,
  ctx = nil,
  prompt = nil,
  status = false,
}

M.think_mark = {
  created = false,
}
return M
