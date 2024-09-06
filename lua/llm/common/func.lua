local M = {}

local state = require("llm.state")
local conf = require("llm.config")

local function IsNotPopwin(winid)
  return state.popwin == nil or winid ~= state.popwin.winid
end

-- define utf8 char length
local function utf8_char_length(byte)
  if byte < 0x80 then
    return 1
  elseif byte >= 0xC0 and byte < 0xE0 then
    return 2
  elseif byte >= 0xE0 and byte < 0xF0 then
    return 3
  elseif byte >= 0xF0 then
    return 4
  end
end

local function utf8_sub(str, start_char, end_char)
  local start_index = 1
  local end_index = #str
  local i = 1
  local char_count = 0
  local byte = string.byte

  while i <= #str do
    local b = byte(str, i)
    char_count = char_count + 1
    local char_len = utf8_char_length(b)

    if char_count == start_char then
      start_index = i
    end
    if char_count == end_char + 1 then
      end_index = i - 1
      break
    end
    i = i + char_len
  end

  return string.sub(str, start_index, end_index)
end

function M.DeepCopy(t)
  local new_t = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      new_t[k] = M.DeepCopy(v)
    else
      new_t[k] = v
    end
  end
  return new_t
end

function M.UpdateCursorPosition(bufnr, winid)
  if IsNotPopwin(winid) then
    winid = state.llm.winid
  end
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(winid, { buffer_line_count, 0 })
end

function M.AppendChunkToBuffer(bufnr, winid, chunk)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1]

  state.cursor.pos = line_count
  local lines = vim.split(chunk, "\n")
  if #lines == 1 then
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { last_line .. lines[1] })
  else
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { last_line .. lines[1] })
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, vim.list_slice(lines, 2))
  end
  if vim.api.nvim_win_is_valid(winid) then
    M.UpdateCursorPosition(bufnr, winid)
  end
  if state.cursor.has_prefix and IsNotPopwin(winid) then
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      conf.prefix[state.cursor.role].hl,
      line_count - 1,
      0,
      #conf.prefix[state.cursor.role].text
    )
  end
  if state.cursor.pos ~= vim.api.nvim_buf_line_count(bufnr) then
    state.cursor.has_prefix = false
  end
end

function M.SetRole(bufnr, winid, role)
  state.cursor.role = role
  M.AppendChunkToBuffer(bufnr, winid, conf.prefix[role].text)
end

function M.NewLine(bufnr, winid)
  M.AppendChunkToBuffer(bufnr, winid, "\n\n")
  state.cursor.has_prefix = true
end

function M.WriteContent(bufnr, winid, content)
  M.AppendChunkToBuffer(bufnr, winid, content)
end

function M.CancelLLM()
  if state.llm.job then
    state.llm.job:shutdown()
    state.llm.job = nil
  end
end

function M.CloseLLM()
  M.CancelLLM()
  state.llm.popup:unmount()

  if conf.configs.save_session and #state.session[state.session.filename] > 2 then
    local filename = nil
    if state.session.filename ~= "current" then
      filename = string.format("%s/%s", conf.configs.history_path, state.session.filename)
    else
      local _filename =
        utf8_sub(state.session[state.session.filename][2].content, 1, conf.configs.max_history_name_length)
      filename = string.format("%s/%s-%s.json", conf.configs.history_path, _filename, os.date("%Y%m%d%H%M%S"))
    end
    local file = io.open(filename, "w")
    file:write(vim.fn.json_encode(state.session[state.session.filename]))
    file:close()
  end
end

function M.ResendLLM()
  state.session[state.session.filename][#state.session[state.session.filename]] = nil
  vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
end

function M.CloseInput()
  state.input.popup:unmount()
end

function M.CloseHistory()
  if state.history.popup then
    state.session = { filename = nil }
    state.history.popup:unmount()
  end
end

function M.ToggleLLM()
  if conf.session.status == 1 then
    if state.llm.popup then
      state.llm.popup:hide()
      state.history.popup:hide()
      conf.session.status = 0
    end
    state.input.popup:hide()
  elseif conf.session.status == 0 then
    if state.llm.popup then
      state.llm.popup:show()
      state.history.popup:show()
      state.llm.winid = state.llm.popup.winid
      vim.api.nvim_set_option_value("spell", false, { win = state.llm.winid })
      vim.api.nvim_set_option_value("wrap", true, { win = state.llm.winid })
      conf.session.status = 1
    end
    state.input.popup:show()
  end
end

function M.ListFilesInPath()
  local files = {}

  local p = io.popen(string.format("ls -At %s  2>/dev/null", conf.configs.history_path))
  for filename in p:lines() do
    if #files < conf.configs.max_history_files then
      table.insert(files, filename)
    else
      os.execute("rm " .. string.format("%s/'%s'", conf.configs.history_path, filename))
    end
  end
  p:close()
  return files
end

function M.MoveHistoryCursor(offset)
  local pos = vim.api.nvim_win_get_cursor(state.history.popup.winid)
  local new_pos = pos[1] + offset
  if new_pos > #state.history.list then
    new_pos = 1
  elseif new_pos < 1 then
    new_pos = #state.history.list
  end
  vim.api.nvim_win_set_cursor(state.history.popup.winid, { new_pos, 0 })
  local new_node = state.history.popup.tree:get_node(new_pos)
  state.history.popup._.on_change(new_node)
end

function M.RefreshLLMText(messages)
  vim.api.nvim_buf_set_lines(state.llm.popup.bufnr, 0, -1, false, {})
  for _, msg in ipairs(messages) do
    if msg.role == "system" then
    else
      M.SetRole(state.llm.popup.bufnr, state.llm.popup.winid, msg.role)
      M.AppendChunkToBuffer(state.llm.popup.bufnr, state.llm.popup.winid, msg.content)
      M.NewLine(state.llm.popup.bufnr, state.llm.popup.winid)
    end
  end
end

function M.WinMapping(win, modes, keys, func, opts)
  local _modes = type(modes) == "string" and { modes } or modes
  local _keys = type(keys) == "string" and { keys } or keys
  for i = 1, #_modes do
    for j = 1, #_keys do
      win:map(_modes[i], _keys[j], func, opts)
    end
  end
end

return M
