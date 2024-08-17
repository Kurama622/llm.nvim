local M = {}

local layout = require("llm.layout")
local conf = require("llm.config")

function M.UpdateCursorPosition(bufnr, winid)
  if layout.popwin == nil or winid ~= layout.popwin.winid then
    winid = layout.llm.winid
  end
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(winid, { buffer_line_count, 0 })
end

function M.AppendChunkToBuffer(bufnr, winid, chunk)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1]

  local lines = vim.split(chunk, "\n")
  if #lines == 1 then
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { last_line .. lines[1] })
  else
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { last_line .. lines[1] })
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, vim.list_slice(lines, 2))
  end
  M.UpdateCursorPosition(bufnr, winid)
end

function M.SetRole(bufnr, winid, role)
  M.AppendChunkToBuffer(bufnr, winid, "## " .. role .. "\n")
end

function M.NewLine(bufnr, winid)
  M.AppendChunkToBuffer(bufnr, winid, "\n\n")
end

function M.WriteContent(bufnr, winid, content)
  M.AppendChunkToBuffer(bufnr, winid, content)
end

function M.CancelLLM()
  if layout.llm.job then
    layout.llm.job:shutdown()
    layout.llm.job = nil
  end
end

function M.CloseLLM()
  M.CancelLLM()
  layout.llm.popup:unmount()
end

function M.ResendLLM()
  conf.session.messages[#conf.session.messages] = nil
  vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
end

function M.CloseInput()
  layout.input.popup:unmount()
end

function M.ToggleLLM()
  if conf.session.status == 1 then
    if layout.llm.popup then
      layout.llm.popup:hide()
      conf.session.status = 0
    end
    layout.input.popup:hide()
  elseif conf.session.status == 0 then
    if layout.llm.popup then
      layout.llm.popup:show()
      layout.llm.winid = layout.llm.popup.winid
      conf.session.status = 1
    end
    layout.input.popup:show()
  end
end

return M
