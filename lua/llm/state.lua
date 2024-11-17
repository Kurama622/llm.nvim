local conf = require("llm.config")
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

M.session = {
  filename = nil,
}

M.popwin = nil

M.app = {
  session = {},
}

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("refresh_popup_layout", { clear = true }),
  callback = function()
    local input_box_width = math.floor(vim.o.columns * 0.7)
    local input_box_start = math.floor(vim.o.columns * 0.15)

    local history_box_width = 27
    local output_box_start = input_box_start

    local output_box_width = math.floor(vim.o.columns * 0.7 - history_box_width - 2)
    local history_box_start = math.floor(output_box_start + vim.o.columns * 0.7 - history_box_width)

    if not conf.configs.save_session then
      output_box_width = input_box_width
    end

    conf._.input_box_opts.position.col = input_box_start
    conf._.input_box_opts.size.width = input_box_width
    conf._.output_box_opts.position.col = output_box_start
    conf._.output_box_opts.size.width = output_box_width
    conf._.history_box_opts.position.col = history_box_start
    conf._.history_box_opts.size.width = history_box_width

    if M.llm.popup ~= nil then
      M.llm.popup:update_layout(conf._.output_box_opts)
    end
    if M.input.popup ~= nil then
      M.input.popup:update_layout(conf._.input_box_opts)
    end
    if M.history.popup ~= nil then
      M.history.popup:update_layout(conf._.history_box_opts)
    end
  end,
})

return M
