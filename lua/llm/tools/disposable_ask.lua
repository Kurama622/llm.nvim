local LOG = require("llm.common.log")
local Popup = require("nui.popup")
local sess = require("llm.session")
local M = {}

function M.handler(_, _, _, _, prompt, opts)
  if type(prompt) == "function" then
    prompt = prompt()
  end

  local input_box = Popup({
    relative = "cursor",
    position = {
      row = 0,
      col = 0,
    },
    size = {
      width = "50%",
      height = "5%",
    },
    enter = true,
    border = {
      style = "rounded",
      text = {
        top = " ask ",
        top_align = "center",
      },
    },
    -- win_options = opts.win_options,
  })

  input_box:mount()
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
