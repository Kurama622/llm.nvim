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
    style = nil,
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

  if options.style == nil then
    local has_cmp, _ = pcall(require, "cmp")
    local has_blink, _ = pcall(require, "blink.cmp")

    if has_blink then
      options.style = "blink.cmp"
    elseif has_cmp then
      options.style = "nvim-cmp"
    else
      options.style = "virtual_text"
    end
  end

  options.timeout = tostring(options.timeout)
  completion:init(options)
end
return M
