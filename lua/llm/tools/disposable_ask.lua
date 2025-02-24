local LOG = require("llm.common.log")
local Popup = require("nui.popup")
local sess = require("llm.session")
local M = {}

function M.handler(_, _, _, _, prompt, opts)
  if type(prompt) == "function" then
    prompt = prompt()
  end

  local options = {
    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
    border = {
      style = opts.style or "rounded",
      text = {
        top = opts.title or " Ask ",
        top_align = "center",
      },
    },
    position = opts.position or {
      row = 0,
      col = 0,
    },
    relative = opts.relative or "cursor",
    size = opts.size or {
      width = "50%",
      height = "5%",
    },
    enter = true,
  }

  options = vim.tbl_deep_extend("force", options, opts or {})

  local input_box = Popup(options)

  input_box:mount()
  vim.api.nvim_set_option_value("filetype", "llm", { buf = input_box.bufnr })
  vim.api.nvim_command("startinsert")
  input_box:map("n", "<cr>", function()
    local description = table.concat(vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true), "\n")
    input_box:unmount()
    sess.LLMSelectedTextHandler(description, true, { prompt = prompt })
  end)

  input_box:map("n", "<esc>", function()
    input_box:unmount()
  end)
end

return M
