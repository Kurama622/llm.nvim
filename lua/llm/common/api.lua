local api = {}

local state = require("llm.state")
local conf = require("llm.config")
local Popup = require("nui.popup")
local Layout = require("nui.layout")
local LOG = require("llm.common.log")
local fio = require("llm.common.file_io")
local luv, json = vim.loop, vim.json

local function IsNotPopwin(winid)
  return not vim.tbl_contains(vim.tbl_keys(state.popwin_list), winid)
end

local function safe_bufload(bufnr)
  local ok, err = pcall(vim.fn.bufload, bufnr)
  if not ok then
    LOG:WARN(string.format("bufload failed for buffer %d: %s", bufnr, err))
  end
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

---@param bufnr integer Buffer number.
---@param method string
---@param params? table LSP request params.
---@param callback fun(items: vim.quickfix.entry[])
local function get_locations(bufnr, method, params, callback)
  local clients = vim.lsp.get_clients({ method = method, bufnr = bufnr })

  if not next(clients) then
    callback({})
    return
  end
  local remaining = #clients

  ---@type vim.quickfix.entry[]
  local all_items = {}

  ---@param result nil|lsp.Location|lsp.Location[]
  ---@param client vim.lsp.Client
  local function on_response(_, result, client)
    local locations = {}
    if result then
      locations = vim.islist(result) and result or { result }
    end
    local items = vim.lsp.util.locations_to_items(locations, client.offset_encoding)
    vim.list_extend(all_items, items)
    remaining = remaining - 1
    if remaining == 0 then
      if vim.tbl_isempty(all_items) then
        callback({ { user_data = { targetUri = nil } } })
      else
        callback(all_items)
      end
    end
  end
  for _, client in ipairs(clients) do
    client:request(method, params, function(_, result)
      on_response(_, result, client)
    end)
  end
end

local function find_definition_node(bufnr, row, col)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, col, row, col)

  local definition_nodes = require("llm.lsp." .. ft) or {}

  -- 一些节点其实是“声明语句”，比如 declaration、definition、specifier 的组合
  local function is_definition_node(n)
    if not n then
      return false
    end
    local kind = definition_nodes[n:type()]
    if kind == true or kind == "container" then
      return true
    end
    local t = n:type()
    return t:match("declaration$") or t:match("definition$") or t:match("specifier$")
  end

  while node and not is_definition_node(node) do
    node = node:parent()
  end

  if not node then
    LOG:DEBUG("Not found definition node.")
    return nil
  end

  local parent = node:parent()
  while parent and definition_nodes[parent:type()] == "container" do
    node = parent
    parent = node:parent()
  end
  return node
end

function api.IsValid(v)
  if type(v) == "table" then
    return not vim.tbl_isempty(v)
  elseif type(v) == "string" then
    return v ~= ""
  elseif type(v) == "number" then
    return v ~= 0
  elseif v == nil or vim.NIL then
    return false
  elseif type(v) == "boolean" then
    return v
  end
end

function api.TrimLeadingWhitespace(str)
  if str == nil then
    return ""
  end
  return (str:gsub("^[\n%s]*", ""))
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

--- @param namespace string|integer Namespace name or Namespace id
--- @param bufnr integer
--- @param hl string
--- @param row_start integer
--- @param col_start integer
--- @param row_end integer
--- @param col_end integer
function api.AddHighlight(namespace, bufnr, hl, row_start, col_start, row_end, col_end)
  local ns = -1

  if type(namespace) == "string" then
    ns = vim.api.nvim_create_namespace(namespace)
  elseif type(namespace) == "number" then
    ns = namespace
  end

  if vim.version.lt(vim.version(), { 0, 11, 0 }) then
    vim.api.nvim_buf_add_highlight(bufnr, ns, hl, row_start, col_start, col_end)
  else
    vim.hl.range(bufnr, ns, hl, { row_start, col_start }, { row_end, col_end }, {})
  end
end

function api.UpdateCursorPosition(bufnr, winid)
  if IsNotPopwin(winid) then
    winid = state.llm.popup.winid
  end
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(winid, { buffer_line_count, 0 })
end

function api.AppendChunkToBuffer(bufnr, winid, chunk, detach)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
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
    api.AddHighlight(
      "role",
      bufnr,
      conf.prefix[state.cursor.role].hl,
      line_count - 1,
      0,
      line_count - 1,
      #conf.prefix[state.cursor.role].text
    )
  end
  if state.cursor.pos ~= vim.api.nvim_buf_line_count(bufnr) then
    state.cursor.has_prefix = false
  end
  -- Fix the issue of markdown rendering in the LLM output window not being timely.
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = bufnr })
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

function api.GetVisualSelectionRange(bufnr, call_mode, opts)
  -- When called by a shortcut key, the current mode is always 'n'.
  -- It is necessary to judge whether it is in visual mode based on the call_mode.
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  call_mode = call_mode or "V"
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
  elseif is_visual_mode(call_mode) then
    -- Get selected text (called by shortcut key)
    -- Fallback to marks if not in visual mode
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
  elseif opts.enable_buffer_context then
    start_pos = { 0, 0, 0, 0 }
    end_pos = { 0, 0, 0, 0 }
  elseif opts.enable_cword_context then
    return { vim.fn.expand("<cword>") }
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
  if is_visual_mode(mode) or opts.enable_buffer_context then
    lines, start_line, start_col, end_line, end_col = api.GetVisualSelectionRange(bufnr, mode, opts)
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
    state.summarize_suggestions.cnt = state.summarize_suggestions.cnt + 1
    state.summarize_suggestions.pattern = {
      start_str = "```",
      end_str = "```",
    }
    local prompt = ""

    if opts.prompt == nil then
      prompt = require("llm.tools.prompts")[name]
    elseif type(opts.prompt) == "function" then
      prompt = opts.prompt()
    end
    state.summarize_suggestions.prompt = string.format(prompt, opts.language)
  end
  return lines, start_line, end_line, start_col, end_col
end

function api.GetAttach(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  opts.diagnostic = opts.diagnostic or conf.configs.diagnostic
  opts.lsp = opts.lsp or conf.configs.lsp

  local lines, start_line, end_line, start_col, end_col = api.MakeInlineContext(opts, bufnr, "attach_to_chat")
  if api.IsValid(opts.lsp) then
    opts.lsp.bufnr_info_list = {
      [bufnr] = {
        start_line = start_line,
        end_line = end_line,
        ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
      },
    }
  end
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

  if api.IsValid(opts.diagnostic) then
    state.input.attach_content = state.input.attach_content
      .. "\n"
      .. api.GetRangeDiagnostics(
        { [bufnr] = { start_line = start_line, end_line = end_line, start_col = start_col, end_col = end_col } },
        opts
      )
  end
  state.input.request_with_lsp = api.lsp_wrap(opts)
  return bufnr
end

function api.ClearAttach()
  state.input.diagnostic_error = nil
  state.input.attach_content = ""
  state.input.lsp_ctx = {
    content = {},
    symbols_location_list = {},
  }
  state.quote_buffers = { buffer_info_list = {} }
  state.quote_files = { file_info_list = {} }
  state.input.request_with_lsp = nil
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
  if state.summarize_suggestions.cnt == 1 then
    state.summarize_suggestions.cnt = state.summarize_suggestions.cnt - 1
    state.summarize_suggestions.ctx = nil
    state.summarize_suggestions.pattern = nil
    api.ResetPrompt()
    state.summarize_suggestions.status = false
  elseif state.summarize_suggestions.cnt > 1 then
    state.summarize_suggestions.cnt = state.summarize_suggestions.cnt - 1
  end
end

function api.CancelLLM()
  for key, job in pairs(state.llm.worker.jobs) do
    job:shutdown()
    LOG:INFO("Suspend " .. key .. "...")
    state.llm.worker.jobs[key] = nil
  end
  state.enabled_cmds = {}
  state.quote_buffers = { buffer_info_list = {} }
  state.quote_files = { file_info_list = {} }
  api.ClearSummarizeSuggestions()
end

function api.SaveSession()
  if conf.configs.save_session and state.session.filename and #state.session[state.session.filename] > 2 then
    for _, changed_file in ipairs(state.session.changed) do
      local filename = nil
      if changed_file ~= "current" then
        filename = string.format("%s/%s", conf.configs.history_path, changed_file)
      else
        local _filename =
          display_sub(state.session[changed_file][2].content, 1, conf.configs.max_history_name_length):gsub(".", {
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
        file:write(json.encode(state.session[changed_file]))
        file:close()
      end
      state.session[filename] = nil
    end
  end
  state.session = { filename = nil, changed = {} }
end

function api.CloseLLM()
  api.CancelLLM()

  -- float
  if state.layout.popup then
    state.layout.popup:unmount()

    for _, comp in ipairs({ state.layout, state.input, state.llm, state.history, state.models }) do
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
      if state.llm.popup then
        pcall(function()
          state.llm.popup:unmount()
        end)
        state.llm.popup = nil
      end
      api.ClearAttach()
      api.ClearSummarizeSuggestions()
      state.history.index = nil
      conf.session.status = -1
    end
  end
  api.SaveSession()
end

function api.ResendLLM()
  table.insert(state.session.changed, state.session.filename)
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
  local json_file_list = vim
    .iter(vim.split(vim.fn.glob(path .. "/*.json"), "\n"))
    :filter(function(item)
      return item ~= ""
    end)
    :totable()

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

function api.RepositionPopupCursor(popup, pos)
  if api.IsValid(pos) then
    vim.api.nvim_win_set_cursor(popup.winid, { pos, 0 })
    local new_node = popup.tree:get_node(pos)
    popup._.on_change(new_node)
  end
end

function api.MoveHistoryCursor(offset)
  local pos = vim.api.nvim_win_get_cursor(state.history.popup.winid)
  local new_pos = pos[1] + offset
  if new_pos > #state.history.list then
    new_pos = 1
  elseif new_pos < 1 then
    new_pos = #state.history.list
  end
  api.RepositionPopupCursor(state.history.popup, new_pos)
end

function api.MoveModelsCursor(offset)
  local pos = vim.api.nvim_win_get_cursor(state.models.popup.winid)
  local new_pos = pos[1] + offset
  if new_pos > #state.models.list then
    new_pos = 1
  elseif new_pos < 1 then
    new_pos = #state.models.list
  end
  api.RepositionPopupCursor(state.models.popup, new_pos)
end

function api.RefreshLLMText(messages, bufnr, winid, detach)
  bufnr = bufnr or state.llm.popup.bufnr
  winid = winid or state.llm.popup.winid
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  for _, msg in ipairs(messages) do
    if msg.role == "system" or msg.role == "tool" or msg.type == "quote_buffers" then
    elseif msg.role == "user" and api.IsValid(msg.content) then
      api.SetRole(bufnr, winid, msg.role, detach)
      if msg.type == "lsp" then
        local symbols_location_info = ""
        for fname, symbol_location in pairs(msg.symbols_location_list) do
          if type(symbol_location) == "table" then
            for _, sym in pairs(symbol_location) do
              symbols_location_info = symbols_location_info
                .. "\n- "
                .. fname
                .. "#L"
                .. sym.start_row
                .. "-"
                .. sym.end_row
                .. " | "
                .. sym.name
            end
          end
        end
        api.AppendChunkToBuffer(
          bufnr,
          winid,
          require("llm.tools.prompts").lsp .. "\n" .. symbols_location_info .. "\n",
          detach
        )
      else
        api.AppendChunkToBuffer(bufnr, winid, msg.content, detach)
      end
      api.NewLine(bufnr, winid, detach)
    elseif api.IsValid(msg.content) then
      api.SetRole(bufnr, winid, msg.role, detach)
      if api.IsValid(msg._llm_reasoning_content) then
        api.AppendChunkToBuffer(bufnr, winid, msg._llm_reasoning_content, detach)
      end
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
    return { state.llm.popup.bufnr }
  end
end

function api.SetItemHl(popup, hl)
  local ns = vim.api.nvim_create_namespace("SeletedItemHl")
  local idx = vim.api.nvim_win_get_cursor(popup.winid)[1]
  local count = vim.api.nvim_buf_line_count(popup.bufnr)
  vim.api.nvim_buf_clear_namespace(popup.bufnr, ns, 0, count)

  api.AddHighlight(ns, popup.bufnr, "LlmGrayLight", 0, 0, count, -1)
  api.AddHighlight(ns, popup.bufnr, hl, idx - 1, 0, idx - 1, -1)
end

---@param hl string
---@param win_name string
function api.FormatHl(hl, win_name)
  local bg = vim.api.nvim_get_hl(0, { name = "CursorLine" }).bg
  local fg = vim.api.nvim_get_hl(0, { name = hl }).fg
  state[win_name].hl = ("Llm%sSelected"):format(string.gsub(win_name, "^%a", string.upper))
  vim.api.nvim_set_hl(0, state[win_name].hl, { fg = fg, bg = bg })
end

function api.HistoryPreview()
  api.ListFilesInPath() -- Clear extra session files
  local opts, picker_cfg = conf.configs.chat_ui_opts.history.split, {}
  if opts then
    picker_cfg.relative = opts.relative
    picker_cfg.layout = opts.layout
    picker_cfg.win_options = opts.win_options
    picker_cfg.buf_options = opts.buf_options
    picker_cfg.size = opts.size
    picker_cfg.position = opts.position
    picker_cfg.select = opts.select
    picker_cfg.preview = opts.preview
  end
  api.Picker("cd " .. conf.configs.history_path .. ";" .. opts.cmd, picker_cfg, function(item)
    api.RefreshLLMText(state.session[item], state.llm.popup.bufnr, state.llm.popup.winid, false)
  end, true, opts.enable_fzf_focus_print)
end

function api.ResetModel(opts, _table, idx)
  for _, key in pairs(state.model_params) do
    local val = _table.models[idx][key]
    if key == "timeout" and val == nil then
      val = conf.configs[key]
    end
    opts[key] = val
  end
end

function api.SetModelInfo(opts, name, idx)
  state.models[name].selected = {}
  for _, key in pairs(state.model_params) do
    state.models[name].selected[key] = opts[key]
  end
  state.models[name].selected._model_idx = idx
end

function api.ModelsPreview(opts, name, on_choice)
  opts = opts or conf.configs
  local _table = opts.models and opts or conf.configs
  name = name or "Chat"
  on_choice = on_choice
    or function(choice, idx)
      if not choice then
        return
      else
        LOG:INFO("Set the current model to", choice)
        api.ResetModel(opts, _table, idx)
        api.SetModelInfo(opts, name, idx)
        if state.models.popup and state.models.popup.winid then
          api.RepositionPopupCursor(state.models.popup, idx)
        end
      end
    end
  state.models[name] = { list = {} }

  for _, item in ipairs(_table.models) do
    table.insert(state.models[name].list, item.name)
  end
  vim.ui.select(state.models[name].list, {
    prompt = "Models:",
    format_item = function(item)
      return item
    end,
  }, on_choice)
end

function api.tbl_slice(t, i, j)
  local n = #t
  i = i or 1
  j = j or n
  if i < 0 then
    i = n + i + 1
  end
  if j < 0 then
    j = n + j + 1
  end
  local sliced = {}
  for k = i, j do
    table.insert(sliced, t[k])
  end
  return sliced
end

---@param func function or callable table, with signature func(key, value)
---@param t table
function api.table_filter(func, t)
  vim.validate({ func = { func, "c" }, t = { t, "t" } })

  local rettab = {}
  for key, entry in pairs(t) do
    if func(key, entry) then
      rettab[key] = entry
    end
  end
  return rettab
end

function api.pcall(fn, res, default_value)
  local status, ret = pcall(fn, res)
  if status then
    return ret
  end
  LOG:ERROR("Illegal JSON string", res)
  return default_value
end

function api.base64_images_encode(paths)
  local res = {}
  local path_tbl = vim.split(paths, "\n")
  for _, path in pairs(path_tbl) do
    local handle = io.popen("base64 " .. path)
    if handle then
      table.insert(res, handle:read("*a"))
      handle:close()
    end
  end
  return res
end

function api.Picker(cmd, ui, callback, force_preview, enable_fzf_focus_print)
  fio.CreateDir("/tmp/")
  local focus_file = "/tmp/llm-fzf-focus-file"
  local position = "50%"
  local size = "60%"
  local previous_session_name = state.session.filename

  local default_ui = {
    position = position,
    size = size,
    relative = "editor",
    layout = {
      dir = "row",
      radio = {
        select = "40%",
        preview = "60%",
      },
    },
    select = {
      border = {
        style = "rounded",
        text = {
          top = " Files ",
          top_align = "center",
        },
      },
      buf_options = { filetype = "llm-picker" },
    },
    preview = {
      border = {
        style = "rounded",
        text = {
          top = " Contents ",
          top_align = "center",
        },
      },
      buf_options = { filetype = "llm" },
    },
  }
  ui = vim.tbl_deep_extend("force", default_ui, ui)

  local select_popup = Popup({
    relative = ui.relative,
    position = ui.position,
    size = ui.size,
    enter = true,
    focusable = true,
    zindex = 50,
    border = ui.select.border,
    win_options = ui.select.win_options,
    buf_options = ui.select.buf_options,
  })
  local preview_popup = nil
  if force_preview then
    preview_popup = Popup({
      enter = false,
      focusable = true,
      zindex = 50,
      border = ui.preview.border,
      buf_options = ui.preview.buf_options,
      win_options = ui.preview.win_options,
    })

    Layout(
      {
        relative = ui.relative,
        position = ui.position,
        size = ui.size,
      },
      Layout.Box({
        Layout.Box(select_popup, { size = ui.layout.radio.select }),
        Layout.Box(preview_popup, { size = ui.layout.radio.preview }),
      }, { dir = ui.layout.dir })
    ):mount()
  else
    select_popup:mount()
  end

  local execute = enable_fzf_focus_print and "execute" or "execute-silent"
  cmd = cmd
    .. " --no-preview"
    .. " --bind='focus:"
    .. execute
    .. "(echo -E {} >"
    .. focus_file
    .. "._COPYING_ "
    .. "&& mv "
    .. focus_file
    .. "._COPYING_ "
    .. focus_file
    .. ")'"

  local filename, filename_abspath = nil, nil
  vim.fn.jobstart(cmd, {
    on_stdout = function()
      local fp = io.open(focus_file, "r")
      if fp then
        filename = fp:read()
        fp:close()
        vim.fn.delete(focus_file)
      end
      if force_preview then
        if filename then
          state.session.filename = filename
          filename_abspath = conf.configs.history_path .. "/" .. filename
          if not state.session[filename] then
            fp = io.open(filename_abspath, "r")
            if fp then
              local messages = json.decode(fp:read())
              state.session[filename] = messages
              fp:close()
            end
          end
          api.RefreshLLMText(state.session[filename], preview_popup.bufnr, preview_popup.winid, true)
        end
      end
    end,
    on_exit = function()
      local selected = vim.fn.getline(1)
      vim.api.nvim_win_close(select_popup.winid, true)

      if selected ~= "" then
        local fzf_item = nil
        if force_preview then
          if vim.uv.fs_stat(filename_abspath) then
            fzf_item = filename_abspath
          end
        else
          if vim.uv.fs_stat(filename) then
            filename = string.gsub(filename, " ", "\\ ")
            fzf_item = filename
          end
        end
        if fzf_item then
          if type(callback) == "function" then
            callback(filename)
          end
        end
      else
        if force_preview then
          -- Reset the current session name
          state.session.filename = state.session[previous_session_name] and previous_session_name or nil
        end
      end
      if force_preview and state.llm.popup then
        vim.api.nvim_set_current_win(state.llm.popup.winid)
      end
    end,
    term = true,
  })
  vim.cmd.startinsert()
end

function api.GetRangeDiagnostics(bufnr_info_list, opts)
  local diagnostics_tbl = {}
  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "Error",
    [vim.diagnostic.severity.WARN] = "Warn",
    [vim.diagnostic.severity.INFO] = "Info",
    [vim.diagnostic.severity.HINT] = "Hint",
  }
  for bufnr, buf_info in pairs(bufnr_info_list) do
    for n_line = buf_info.start_line, buf_info.end_line do
      local diagnostics = vim.diagnostic.get(bufnr, {
        lnum = n_line - 1,
        severity = opts.diagnostic,
      })

      for i, diag in ipairs(diagnostics) do
        local level = severity_map[diag.severity] or "Unknow"
        if level == "Error" then
          state.input.diagnostic_error = true
        end
        local msg = string.format(tostring(i) .. ". %s: %s", level, diag.message:gsub("\n", "\n\t"))
        if diagnostics_tbl[diag.lnum] == nil then
          diagnostics_tbl[diag.lnum] = { msg }
        elseif not vim.tbl_contains(diagnostics_tbl[diag.lnum], msg) then
          table.insert(diagnostics_tbl[diag.lnum], msg)
        end
      end
    end
  end

  local diagnostics_prompt = state.input.diagnostic_error and ""
    or "\nAll dependency libraries, packages, or header files involved in the code have been correctly imported, so there is no need to pay attention to such dependency issues.\n"

  if api.IsValid(diagnostics_tbl) then
    local diagnostics_content = ""
    for _, diags in pairs(diagnostics_tbl) do
      diagnostics_content = diagnostics_content .. "\n" .. table.concat(diags, "\n")
    end
    return diagnostics_prompt .. "\nThe code's diagnostics:" .. diagnostics_content
  end
  return diagnostics_prompt
end

function api.lsp_wrap(opts)
  if not api.IsValid(opts.lsp) then
    return
  end

  opts.lsp.bufnr_info_list = vim.tbl_map(function(buf_info)
    if api.IsValid(opts.lsp[buf_info.ft]) and api.IsValid(opts.lsp[buf_info.ft].methods) then
      return buf_info
    end
    return nil
  end, opts.lsp.bufnr_info_list)
  if api.IsValid(opts.lsp.bufnr_info_list) then
    return function(llm_request)
      if api.IsValid(state.input.attach_content) then
        api.lsp_request(opts.lsp, function(symbol, exist)
          if exist then
            local symbol_location = {
              start_row = symbol.start_row,
              end_row = symbol.end_row,
              start_col = symbol.start_col,
              end_col = symbol.end_col,
              name = symbol.name,
              bufnr = symbol.bufnr,
            }

            -- Deduplicate and take the union of the returned symbol definitions.
            if not api.IsValid(state.input.lsp_ctx.symbols_location_list[symbol.fname]) then
              state.input.lsp_ctx.symbols_location_list[symbol.fname] = { symbol_location }
            else
              local placed = false

              for i, item in pairs(state.input.lsp_ctx.symbols_location_list[symbol.fname]) do
                if item.start_row > symbol_location.start_row and item.end_row < symbol_location.end_row then
                  state.input.lsp_ctx.symbols_location_list[symbol.fname][i] = symbol_location
                  placed = true
                  break
                elseif item.start_row <= symbol_location.start_row and item.end_row >= symbol_location.end_row then
                  placed = true
                  break
                end
              end
              if not placed then
                table.insert(state.input.lsp_ctx.symbols_location_list[symbol.fname], symbol_location)
              end
            end
          end
          if symbol.done then
            for fname, symbol_location in pairs(state.input.lsp_ctx.symbols_location_list) do
              for _, sym in pairs(symbol_location) do
                table.insert(
                  state.input.lsp_ctx.content,
                  ("- %s#L%d-%d | %s\n```%s\n%s\n```"):format(
                    fname,
                    sym.start_row,
                    sym.end_row,
                    sym.name,
                    vim.api.nvim_get_option_value("filetype", { buf = sym.bufnr }),
                    table.concat(
                      vim.api.nvim_buf_get_text(
                        sym.bufnr,
                        sym.start_row - 1,
                        sym.start_col - 1,
                        sym.end_row - 1,
                        sym.end_col - 1,
                        {}
                      ),
                      "\n"
                    )
                  )
                )
              end
            end
            if
              not state.input.lsp_ctx.symbols_location_list.lsp_prompt and api.IsValid(state.input.lsp_ctx.content)
            then
              table.insert(state.input.lsp_ctx.content, 1, require("llm.tools.prompts").lsp)
              state.input.lsp_ctx.symbols_location_list.lsp_prompt = true
            end
            llm_request()
          end
        end)
      else
        llm_request()
      end
    end
  end
  return nil
end

--- 主函数：获取选中代码中所有符号的定义
function api.lsp_request(cfg, callback)
  -- initialize symbols_to_query, queried_symbols and lsp_ctx
  local symbols_to_query = {}
  local queried_symbols = {}

  for bufnr, _ in pairs(cfg.bufnr_info_list) do
    state.input.lsp_ctx[bufnr] = {}
    symbols_to_query[bufnr] = {}
    queried_symbols[bufnr] = {}
  end

  local function traverse(node, bufnr)
    local node_start_line, _, node_end_line, _ = node:range()
    if
      math.max(state.input.lsp_ctx[bufnr].start_line, node_start_line)
      <= math.min(state.input.lsp_ctx[bufnr].end_line, node_end_line)
    then
      -- 我们只关心标识符和函数名 (call_expression 的一部分)
      if node:type():match("identifier$") then
        local name = vim.treesitter.get_node_text(node, bufnr)
        if not queried_symbols[bufnr][name] then
          table.insert(symbols_to_query[bufnr], { name = name, node = node })
          queried_symbols[bufnr][name] = true
        end
      end
      for child in node:iter_children() do
        traverse(child, bufnr)
      end
    end
  end

  for bufnr, buf_info in pairs(cfg.bufnr_info_list) do
    state.input.lsp_ctx[bufnr].start_line = buf_info.start_line - 1
    state.input.lsp_ctx[bufnr].end_line = buf_info.end_line - 1
    state.input.lsp_ctx[bufnr].ft = buf_info.ft
    -- 2. 使用 Tree-sitter 获取该范围内的所有标识符
    local parser = vim.treesitter.get_parser(bufnr)
    if not parser then
      LOG:WARN(string.format("Lack of %s's treesitter parser"), buf_info.ft)
      return
    end

    if cfg.root_dir then
      state.input.lsp_ctx[bufnr].root_dir = vim.fs.root(bufnr, cfg.root_dir)
    end
    state.input.lsp_ctx[bufnr].fname = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
    local root = parser:parse()[1]:root()
    traverse(root, bufnr)
  end

  local symbols_to_query_cnt = 0
  for _, query_symbols in pairs(symbols_to_query) do
    symbols_to_query_cnt = symbols_to_query_cnt + #query_symbols
  end

  if symbols_to_query_cnt == 0 then
    LOG:WARN("No searchable symbols were found in the district.")
    return
  end

  local supported_method_cnt = {}
  for bufnr, _ in pairs(symbols_to_query) do
    supported_method_cnt[bufnr] = 0
  end

  local query_symbols_method_cnt = 0
  for bufnr, query_symbols in pairs(symbols_to_query) do
    for n_method, method in pairs(cfg[state.input.lsp_ctx[bufnr].ft].methods) do
      local clients = vim.lsp.get_clients({ method = method, bufnr = bufnr })

      if #clients == 0 then
        LOG:WARN(state.input.lsp_ctx[bufnr].ft .. " lacks an LSP client.")
        callback({ ["done"] = true })
        return
      end
      for i = 1, #clients do
        if clients[i].supports_method("textDocument/" .. method, bufnr) then
          supported_method_cnt[bufnr] = supported_method_cnt[bufnr] + 1
        else
          cfg[state.input.lsp_ctx[bufnr].ft].methods[n_method] = nil
          LOG:DEBUG(vim.lsp._unsupported_method("textDocument/" .. method))
        end
      end
    end
    query_symbols_method_cnt = query_symbols_method_cnt + #query_symbols * supported_method_cnt[bufnr]
  end

  -- 3. 对每个符号异步调用 LSP
  local n_symbol = 0
  for buf, query_symbols in pairs(symbols_to_query) do
    for _, symbol in pairs(query_symbols) do
      local row, col = symbol.node:start()
      local params = {
        textDocument = vim.lsp.util.make_text_document_params(buf),
        position = { line = row, character = col },
      }

      for _, method in pairs(cfg[state.input.lsp_ctx[buf].ft].methods) do
        get_locations(buf, "textDocument/" .. method, params, function(locations)
          n_symbol = n_symbol + 1

          for n_location, location in pairs(locations) do
            local lsp_request_done = (n_symbol == query_symbols_method_cnt)
            local uri = location.user_data.targetUri or location.user_data.uri
            local range = location.user_data.targetRange or location.user_data.range
            if not uri or not range then
              LOG:DEBUG("symbol '" .. symbol.name .. "': Invalid LSP Location")
              if lsp_request_done then
                callback({ ["done"] = true })
              end
              return
            end

            local fname = vim.uri_to_fname(uri)
            -- 确保 buffer 已加载

            local bufnr = vim.fn.bufadd(fname)
            safe_bufload(bufnr)

            -- 取 LSP 返回的位置
            row = range.start.line
            col = range.start.character

            if
              (
                fname == state.input.lsp_ctx[buf].fname
                and row >= state.input.lsp_ctx[buf].start_line
                and row <= state.input.lsp_ctx[buf].end_line
              )
              or (
                api.IsValid(state.input.lsp_ctx[buf].root_dir)
                and string.match(fname, state.input.lsp_ctx[buf].root_dir) == nil
              )
            then
              if lsp_request_done then
                callback({ ["done"] = true })
              end
              return
            end
            local node = find_definition_node(bufnr, row, col)

            if node then
              local node_start_row, node_start_col, node_end_row, node_end_col = vim.treesitter.get_node_range(node)
              local relative_fname = state.input.lsp_ctx[buf].root_dir ~= nil
                  and vim.fs.relpath(state.input.lsp_ctx[buf].root_dir, fname)
                or fname
              callback({
                ["name"] = symbol.name,
                ["fname"] = relative_fname,
                ["start_row"] = node_start_row + 1,
                ["end_row"] = node_end_row + 1,
                ["start_col"] = node_start_col + 1,
                ["end_col"] = node_end_col + 1,
                ["bufnr"] = bufnr,
                ["done"] = lsp_request_done and (n_location == #locations),
              }, true)
            else
              if lsp_request_done and (n_location == #locations) then
                callback({ ["done"] = true })
              else
                callback({ ["done"] = false })
              end
            end
          end
        end)
      end
    end
  end
end

function api.AppendLspMsg(bufnr, winid)
  api.SetRole(bufnr, winid, "user")

  local symbols_location_info = ""
  for fname, symbol_location in pairs(state.input.lsp_ctx.symbols_location_list) do
    if type(symbol_location) == "table" then
      for _, sym in pairs(symbol_location) do
        symbols_location_info = symbols_location_info
          .. "\n- "
          .. fname
          .. "#L"
          .. sym.start_row
          .. "-"
          .. sym.end_row
          .. " | "
          .. sym.name
      end
    end
  end
  api.AppendChunkToBuffer(bufnr, winid, require("llm.tools.prompts").lsp .. "\n" .. symbols_location_info .. "\n")
  api.NewLine(bufnr, winid)
end

return api
