-- Taken from the awesome:
-- https://github.com/S1M0N38/dante.nvim

local conf = require("llm.config")

local api = vim.api

---@class Diff
---@field bufnr number The buffer number of the original buffer
---@field cursor_pos number[] The position of the cursor in the original buffer
---@field filetype string The filetype of the original buffer
---@field contents string[] The contents of the original buffer
---@field winnr number The window number of the original buffer
---@field diff table The table containing the diff buffer and window
---@field valid boolean Whether the diff is valid
local Diff = { style = "default" }

---@class DiffArgs
---@field bufnr number
---@field cursor_pos? number[]
---@field filetype string
---@field contents string[]
---@field winnr number

---@param args DiffArgs
---@return Diff
function Diff.new(args)
  local self = setmetatable({
    bufnr = args.bufnr,
    contents = args.contents,
    cursor_pos = args.cursor_pos or nil,
    filetype = args.filetype,
    winnr = args.winnr,
  }, { __index = Diff })
  Diff.valid = true
  if conf.configs.display.diff.disable_diagnostic then
    vim.diagnostic.enable(false, { bufnr = args.bufnr })
  end
  -- Set the diff properties
  vim.cmd("set diffopt=" .. table.concat(conf.configs.display.diff.opts, ","))

  local vertical = (conf.configs.display.diff.layout == "vertical")

  -- Get current properties
  local buf_opts = {
    ft = (self.filetype == "C++" and "cpp" or self.filetype),
  }
  local win_opts = {
    wrap = vim.wo.wrap,
    lbr = vim.wo.linebreak,
    bri = vim.wo.breakindent,
  }

  -- Create the diff buffer
  local diff = {
    buf = vim.api.nvim_create_buf(false, true),
    name = "[LLMAction] " .. math.random(10000000),
  }
  api.nvim_buf_set_name(diff.buf, diff.name)
  for opt, value in pairs(buf_opts) do
    api.nvim_set_option_value(opt, value, { buf = diff.buf })
  end

  -- Create the diff window
  diff.win = api.nvim_open_win(diff.buf, true, { vertical = vertical, win = self.winnr })
  for opt, value in pairs(win_opts) do
    vim.api.nvim_set_option_value(opt, value, { win = diff.win })
  end
  -- Set the diff buffer to the contents, prior to any modifications
  api.nvim_buf_set_lines(diff.buf, 0, 0, true, self.contents)
  if self.cursor_pos then
    api.nvim_win_set_cursor(diff.win, { self.cursor_pos[1], self.cursor_pos[2] })
  end

  -- Begin diffing
  api.nvim_set_current_win(diff.win)
  vim.cmd("diffthis")
  api.nvim_set_current_win(self.winnr)
  vim.cmd("diffthis")

  self.diff = diff

  return self
end

---Accept the diff
---@return nil
function Diff:accept()
  Diff.valid = false
  return self:teardown()
end

---Reject the diff
---@return nil
function Diff:reject()
  Diff.valid = false
  self:teardown()
  return api.nvim_buf_set_lines(self.bufnr, 0, -1, true, self.contents)
end

---Close down the diff
---@return nil
function Diff:teardown()
  Diff.valid = false
  if conf.configs.display.diff.disable_diagnostic then
    vim.diagnostic.enable(true, { bufnr = self.bufnr })
  end
  vim.cmd("diffoff")
  api.nvim_win_close(self.diff.win, false)
end

return Diff
