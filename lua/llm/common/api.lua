local api = {}
local luv = vim.loop

local state = require("llm.state")
local conf = require("llm.config")
local Popup = require("nui.popup")
local Layout = require("nui.layout")
local LOG = require("llm.common.log")

local function IsNotPopwin(winid)
  return state.popwin == nil or winid ~= state.popwin.winid
end

local function escape_string(str)
  local replacements = {
    ["\\"] = "\\\\",
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ['"'] = '\\"',
    ["'"] = "\\'",
    [" "] = "\\ ",
    ["("] = "\\(",
    [")"] = "\\)",
  }
  return (str:gsub(".", replacements))
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

local function utf8_sub(s, i, j)
  i = i or 1
  j = j or -1

  local start, stop = i, #s
  local utf8_len, pos = 0, 1

  while pos <= stop do
    local c = s:byte(pos)
    local char_len = utf8_char_length(c)
    utf8_len = utf8_len + char_len
    pos = pos + char_len
    if utf8_len >= j then
      stop = pos - 1
      break
    end
  end
  return s:sub(start, stop)
end

local function display_sub(s, i, j)
  i = i or 1
  j = j or -1

  local start, stop = i, #s
  local utf8_len, pos = 0, 1

  while pos <= stop do
    local c = s:byte(pos)
    local char_len = utf8_char_length(c)
    utf8_len = utf8_len + vim.api.nvim_strwidth(s:sub(pos, pos + char_len - 1))
    pos = pos + char_len
    if utf8_len >= j then
      stop = pos - 1
      break
    end
  end
  return s:sub(start, stop)
end

function api.TrimLeadingWhitespace(str)
  if str == nil then
    return ""
  end
  return (str:gsub("^[\n%s]*", ""))
end

function api.DeepCopy(t)
  local new_t = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      new_t[k] = api.DeepCopy(v)
    else
      new_t[k] = v
    end
  end
  return new_t
end

function api.GetFileType(bufnr)
  bufnr = bufnr or 0
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

  if ft == "cpp" then
    return "C++"
  end

  return ft
end

function api.VisMode2NorMode()
  local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)
end

function api.GetUserRequestArgs(args, env)
  local chunk, err = load(args, nil, "t", env)

  if not chunk then
    vim.notify("Custom args error: " .. err, vim.log.levels.ERROR)
  else
    local status, result = pcall(chunk)

    if status then
      return result
    else
      vim.notify("Custom args error: " .. tostring(result), vim.log.levels.ERROR)
    end
  end
end

function api.UpdateCursorPosition(bufnr, winid)
  if IsNotPopwin(winid) then
    winid = state.llm.winid
  end
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(winid, { buffer_line_count, 0 })
end

function api.AppendChunkToBuffer(bufnr, winid, chunk, detach)
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
  if vim.api.nvim_win_is_valid(winid) and not detach then
    api.UpdateCursorPosition(bufnr, winid)
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

function api.SetRole(bufnr, winid, role, detach)
  state.cursor.role = role
  api.AppendChunkToBuffer(bufnr, winid, conf.prefix[role].text, detach)
end

function api.NewLine(bufnr, winid, detach)
  api.AppendChunkToBuffer(bufnr, winid, "\n\n", detach)
  state.cursor.has_prefix = true
end

---@param bufnr number
---@param winid number
---@param content string
function api.WriteContent(bufnr, winid, content)
  api.AppendChunkToBuffer(bufnr, winid, content)
end

---@param mode string
---@return boolean
local function is_visual_mode(mode)
  return mode == "v" or mode == "V" or mode == "\x16"
end

function api.GetVisualSelectionRange(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- store the current mode
  local mode = vim.fn.mode()
  -- if we're not in visual mode, we need to re-enter it briefly
  local is_visual = is_visual_mode(mode)

  -- Get positions
  local start_pos, end_pos
  if is_visual then
    -- If we're in visual mode, use 'v' and '.'
    start_pos = vim.fn.getpos("v")
    end_pos = vim.fn.getpos(".")
  else
    -- Fallback to marks if not in visual mode
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
  end

  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  -- normalize the range to start < end
  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  -- get whole buffer if there is no current/previous visual selection
  if start_line == 0 then
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    start_line = 1
    start_col = 0
    end_line = #lines
    end_col = #lines[#lines]
  end

  local n_lines = #lines
  -- Handle partial line selections
  if n_lines > 0 then
    if mode == "V" or (not is_visual and vim.fn.visualmode() == "V") then
      -- For line-wise selection, use full lines
      start_col = 1
      end_col = #lines[#lines]
    else
      -- For character-wise selection, respect the columns
      if n_lines == 1 then
        lines[1] = utf8_sub(lines[1], start_col, end_col)
      else
        lines[1] = utf8_sub(lines[1], start_col, #lines[1])
        if mode == "v" then
          lines[n_lines] = utf8_sub(lines[n_lines], 1, end_col)
        else
          for n = 2, n_lines - 1 do
            lines[n] = utf8_sub(lines[n], start_col, #lines[n])
          end
          lines[n_lines] = utf8_sub(lines[n_lines], start_col, end_col)
        end
      end
    end
  end
  return lines, start_line, start_col, end_line, end_col
end

function api.GetVisualSelection(lines)
  -- Only retrieve the first return parameter of the `GetVisualSelectionRange` function.
  lines = lines or api.GetVisualSelectionRange()
  local seletion = table.concat(lines, "\n")
  return seletion
end

function api.MakeInlineContext(opts, bufnr, name)
  local lines, start_line, start_col, end_line, end_col

  local mode = opts.mode or vim.fn.mode()
  if is_visual_mode(mode) then
    lines, start_line, start_col, end_line, end_col = api.GetVisualSelectionRange(bufnr)
  else
    local pos = vim.fn.getpos(".")
    lines = {}
    start_line, end_line = pos[2], pos[2]
    start_col, end_col = pos[3] - 1, pos[3] - 1
  end

  if opts.inline_assistant then
    local winnr = vim.api.nvim_get_current_win()
    local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
    local context = {
      bufnr = bufnr,
      filetype = api.GetFileType(bufnr),
      contents = lines,
      winnr = winnr,
      cursor_pos = cursor_pos,
      start_line = start_line,
      start_col = start_col,
      end_line = end_line,
      end_col = end_col,
    }
    state.summarize_suggestions.ctx = context
    state.summarize_suggestions.pattern = {
      -- start_str = "<!%-%-suggestion%-%->\n```",
      -- end_str = "```\n<!%-%-/suggestion%-%->",
      start_str = "```",
      end_str = "```",
    }
    state.summarize_suggestions.prompt =
      -- string.format(require("llm.tools.prompts")[name], "<!--suggestion-->", "<!--/suggestion-->", opts.language)
      string.format(require("llm.tools.prompts")[name], "", "", opts.language)
  end
  return lines
end

function api.GetAttach(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = api.MakeInlineContext(opts, bufnr, "attach_to_chat")
  api.VisMode2NorMode()

  if opts.is_codeblock and not vim.tbl_isempty(lines) then
    state.input.attach_content = string.format(
      [[```%s
%s
```]],
      vim.bo.ft,
      api.GetVisualSelection(lines)
    )
  else
    state.input.attach_content = api.GetVisualSelection(lines)
  end
  return bufnr
end

function api.ClearAttach()
  state.input.attach_content = nil
end

function api.UpdatePrompt(name)
  if state.summarize_suggestions.prompt and not state.summarize_suggestions.status then
    if state.session[name][1].role == "system" then
      state.session[name][1].content =
        string.format("%s\n%s", state.session[name][1].content, state.summarize_suggestions.prompt)
      state.summarize_suggestions.status = true
    else
      table.insert(state.session[name], 1, { role = "system", content = state.summarize_suggestions.prompt })
    end
  end
end

function api.ResetPrompt()
  if state.summarize_suggestions.status then
    if state.session[state.session.filename][1].role == "system" then
      state.session[state.session.filename][1].content = conf.configs.prompt
      state.summarize_suggestions.prompt = nil
      state.summarize_suggestions.status = false
    end
  end
end

function api.ClearSummarizeSuggestions()
  state.summarize_suggestions.ctx = nil
  state.summarize_suggestions.pattern = nil
  api.ResetPrompt()
  state.summarize_suggestions.status = false
end

function api.CancelLLM()
  if state.llm.worker.job then
    state.llm.worker.job:shutdown()
    LOG:INFO("Suspend output...")
    state.llm.worker.job = nil
  end
end

function api.CloseLLM()
  if state.llm.worker.job then
    state.llm.worker.job:shutdown()
    LOG:INFO("Suspend output...")
    vim.wait(200, function() end)
    state.llm.worker.job = nil
  end
  -- float
  if state.layout.popup then
    state.layout.popup:unmount()

    for _, comp in ipairs({ state.layout, state.input, state.llm, state.history }) do
      comp.popup = nil
    end
    api.ClearAttach()
    api.ClearSummarizeSuggestions()
    conf.session.status = -1
    vim.api.nvim_command("doautocmd BufEnter")
  else
    if state.input.popup then
      state.input.popup:unmount()
      state.input.popup = nil
      api.ClearAttach()
      vim.api.nvim_command("doautocmd BufEnter")
      return
    else
      LOG:TRACE("Close Split window")
      pcall(vim.api.nvim_win_close, state.llm.winid, true)
      vim.api.nvim_buf_delete(state.llm.bufnr, { force = true })
      if state.history.popup then
        state.history.popup:unmount()
        state.history.popup = nil
      end
      api.ClearAttach()
      api.ClearSummarizeSuggestions()
      state.history.index = nil
      conf.session.status = -1
    end
  end

  if conf.configs.save_session and state.session.filename and #state.session[state.session.filename] > 2 then
    local filename = nil
    if state.session.filename ~= "current" then
      filename = string.format("%s/%s", conf.configs.history_path, state.session.filename)
    else
      local _filename = display_sub(
        state.session[state.session.filename][2].content,
        1,
        conf.configs.max_history_name_length
      ):gsub(".", {
        ["["] = "\\[",
        ["]"] = "\\]",
        ["/"] = "%",
        ["\n"] = " ",
        ["\r"] = " ",
      })

      filename = string.format("%s/%s-%s.json", conf.configs.history_path, _filename, os.date("%Y%m%d%H%M%S"))
    end
    local file = io.open(filename, "w")
    if file then
      file:write(vim.fn.json_encode(state.session[state.session.filename]))
      file:close()
    end
  end
  state.session = { filename = nil }
end

function api.ResendLLM()
  state.session[state.session.filename][#state.session[state.session.filename]] = nil
  vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
end

function api.CloseInput()
  state.input.popup:unmount()
end

function api.CloseHistory()
  if state.history.popup then
    state.session = { filename = nil }
    state.history.popup:unmount()
  end
end

function api.ListFilesInPath()
  local path = conf.configs.history_path
  local json_file_list = vim.split(vim.fn.glob(path .. "/*.json"), "\n")

  for i = 1, #json_file_list do
    json_file_list[i] = vim.fs.basename(json_file_list[i])
  end

  table.sort(json_file_list, function(a, b)
    return luv.fs_stat(string.format("%s/%s", path, a)).mtime.sec
      > luv.fs_stat(string.format("%s/%s", path, b)).mtime.sec
  end)

  for i = 1, #json_file_list do
    if i > conf.configs.max_history_files then
      vim.fn.delete(string.format("%s/%s", path, json_file_list[i]))
      table.remove(json_file_list, i)
    end
  end
  return json_file_list
end

function api.MoveHistoryCursor(offset)
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

function api.MoveModelsCursor(offset)
  local pos = vim.api.nvim_win_get_cursor(state.models.popup.winid)
  local new_pos = pos[1] + offset
  if new_pos > #state.models.list then
    new_pos = 1
  elseif new_pos < 1 then
    new_pos = #state.models.list
  end
  vim.api.nvim_win_set_cursor(state.models.popup.winid, { new_pos, 0 })
  local new_node = state.models.popup.tree:get_node(new_pos)
  state.models.popup._.on_change(new_node)
end

function api.RefreshLLMText(messages, bufnr, winid, detach)
  bufnr = bufnr or state.llm.popup.bufnr
  winid = winid or state.llm.popup.winid
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  for _, msg in ipairs(messages) do
    if msg.role == "system" then
    else
      api.SetRole(bufnr, winid, msg.role, detach)
      api.AppendChunkToBuffer(bufnr, winid, msg.content, detach)
      api.NewLine(bufnr, winid, detach)
    end
  end
end

function api.SetFloatKeyMapping(popup, modes, keys, func, opts)
  local _modes = type(modes) == "string" and { modes } or modes
  local _keys = type(keys) == "string" and { keys } or keys
  for i = 1, #_modes do
    for j = 1, #_keys do
      popup:map(_modes[i], _keys[j], func, opts)
    end
  end
end

function api.SetSplitKeyMapping(modes, keys, func, opts)
  local _modes = type(modes) == "string" and { modes } or modes
  local _keys = type(keys) == "string" and { keys } or keys
  for i = 1, #_modes do
    for j = 1, #_keys do
      vim.keymap.set(_modes[i], _keys[j], func, opts)
    end
  end
end

function api.InsertTextLine(bufnr, linenr, text)
  vim.api.nvim_buf_set_lines(bufnr, linenr, linenr, false, { text })
end

function api.ReplaceTextLine(bufnr, linenr, text)
  vim.api.nvim_buf_set_lines(bufnr, linenr, linenr + 1, false, { text })
end

function api.RemoveTextLines(bufnr, start_linenr, end_linenr)
  vim.api.nvim_buf_set_lines(bufnr, start_linenr, end_linenr, false, {})
end

function api.CreatePopup(text, focusable, opts)
  local options = {
    focusable = focusable,
    border = { style = "rounded", text = { top = text, top_align = "center" } },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})

  return Popup(options)
end

function api.CreateLayout(_width, _height, boxes, opts)
  local options = {
    relative = "editor",
    position = "50%",
    size = {
      width = _width,
      height = _height,
    },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})
  return Layout(options, boxes)
end

function api.SetBoxOpts(box_list, opts)
  for i, v in ipairs(box_list) do
    vim.api.nvim_set_option_value("filetype", opts.filetype[i], { buf = v.bufnr })
    vim.api.nvim_set_option_value("buftype", opts.buftype, { buf = v.bufnr })
    vim.api.nvim_set_option_value("spell", opts.spell, { win = v.winid })
    vim.api.nvim_set_option_value("wrap", opts.wrap, { win = v.winid })
    vim.api.nvim_set_option_value("linebreak", opts.linebreak, { win = v.winid })
    vim.api.nvim_set_option_value("number", opts.number, { win = v.winid })
  end
end

--- Refer: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/utils.lua
local function zz()
  local lnum1 = vim.api.nvim_win_get_cursor(0)[1]
  local lcount = vim.api.nvim_buf_line_count(0)
  local zb = "keepj norm! %dzb"
  if lnum1 == lcount then
    vim.fn.execute(zb:format(lnum1))
    return
  end
  vim.cmd("norm! zvzz")
  vim.cmd("norm! L")
  lnum1 = vim.api.nvim_win_get_cursor(0)[1]
  local lnum2 = vim.api.nvim_win_get_cursor(0)[1]
  if lnum2 + vim.fn.getwinvar(0, "&scrolloff") >= lcount then
    vim.fn.execute(zb:format(lnum2))
  end
  if lnum1 ~= lnum2 then
    vim.cmd("keepj norm! ``")
  end
end

--- Refer: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/previewer/builtin.lua
--- Scrolls the specified window in the given direction.
--- @param winid number: The ID of the window to scroll.
--- @param direction string: The direction to scroll.
function api.ScrollWindow(winid, direction)
  local height = vim.api.nvim_win_get_height(winid)
  local input = ({
    ["top"] = "gg",
    ["bottom"] = "G",
    ["half-page-up"] = ("%c"):format(0x15), -- [[]]
    ["half-page-down"] = ("%c"):format(0x04), -- [[]]
    ["page-up"] = ("%c"):format(0x02), -- [[]]
    ["page-down"] = ("%c"):format(0x06), -- [[]]
    ["line-up"] = "Mgk", -- ^Y doesn't seem to work
    ["line-down"] = "Mgj", -- ^E doesn't seem to work
  })[direction]

  pcall(vim.api.nvim_win_call, winid, function()
    -- ctrl-b (page-up) behaves in a non consistent way, unlike ctrl-u, if it can't
    -- scroll a full page upwards it won't move the cursor, if the cursor is within
    -- the first page it will still move the cursor to the bottom of the page (!?)
    -- we therefore need special handling for both scenarios with `ctrl-b`:
    --   (1) If the cursor is at line 1, do nothing
    --   (2) Else, test the cursor before and after, if the new position is further
    --       down the buffer than the original, we're in the first page ,goto line 1
    local is_ctrl_b = string.byte(input, 1) == 2
    local pos = is_ctrl_b and vim.api.nvim_win_get_cursor(0)
    if is_ctrl_b and pos[1] == 1 then
      return
    end
    vim.cmd([[norm! ]] .. input)
    if is_ctrl_b and vim.api.nvim_win_get_cursor(0)[1] + 1 <= height then
      vim.api.nvim_win_set_cursor(0, { math.max(pos[1] - height, 1), pos[2] })
    end
    zz()
  end)
end

function api.GetChatUiBufnrList()
  if conf.configs.style == "float" then
    return { state.input.popup.bufnr, state.llm.popup.bufnr }
  else
    return { state.llm.bufnr }
  end
end
return api
