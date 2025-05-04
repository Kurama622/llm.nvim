local completion = require("llm.common.completion")
local M = {}
function M.handler(name, F, state, _, prompt, opts)
  local options = {
    fim = true,
    context_window = 12800,
    context_ratio = 0.75,
    stream = false,
    parse_handler = nil,
    stdout_handler = nil,
    stderr_handler = nil,
    timeout = 10,
    throttle = 400, -- only send the request every x milliseconds, use 0 to disable throttle.
    -- debounce the request in x milliseconds, set to 0 to disable debounce
    debounce = 200,
    filetypes = {},
    default_filetype_enabled = true,
    auto_trigger = true,
    only_trigger_by_keywords = true,
    style = "virtual_text",
    keymap = {
      virtual_text = {
        accept = {
          mode = "i",
          keys = "<A-a>",
        },
        next = {
          mode = "i",
          keys = "<A-n>",
        },
        prev = {
          mode = "i",
          keys = "<A-p>",
        },
      },
      toggle = {
        mode = "n",
        keys = "<leader>cp",
      },
    },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})

  options.timeout = tostring(options.timeout)
  completion:init(options)
end
return M
