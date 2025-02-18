local api = {}
local luv = vim.loop

local state = require("llm.state")
local conf = require("llm.config")
local job = require("plenary.job")
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

function api.trim_leading_whitespace(str)
  if str == nil then
    return ""
  end
  return (str:gsub("^[\n%s]*", ""))
end

function api.wait_ui_opts(win_opts)
  local ui_width = vim.api.nvim_strwidth(conf.configs.spinner.text[1])
  local opts = {
    relative = "cursor",
    position = {
      row = -1,
      col = 1,
    },
    size = {
      height = 1,
      width = ui_width,
    },
    enter = false,
    focusable = true,
    zindex = 50,
    border = {
      style = "none",
    },
    win_options = {
      winblend = 0,
      winhighlight = "Normal:NONE,FloatBorder:FloatBorder",
    },
  }
  opts = vim.tbl_deep_extend("force", opts, win_opts or {})
  return opts
end

function api.show_spinner(waiting_state)
  local spinner_frames = conf.configs.spinner.text
  local spinner_hl = conf.configs.spinner.hl
  local frame = 1

  local timer = vim.loop.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if waiting_state.box then
        waiting_state.box:unmount()
        if not waiting_state.finish then
          waiting_state.box = Popup(waiting_state.box_opts)
          waiting_state.box:mount()
          waiting_state.bufnr = waiting_state.box.bufnr
          waiting_state.winid = waiting_state.box.winid
        end
      end
      if not vim.api.nvim_win_is_valid(waiting_state.winid) then
        timer:stop()
        return
      end

      vim.api.nvim_buf_set_lines(waiting_state.bufnr, 0, -1, false, { spinner_frames[frame] })
      vim.api.nvim_buf_add_highlight(waiting_state.bufnr, -1, spinner_hl, 0, 0, -1)

      frame = frame % #spinner_frames + 1
    end)
  )
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
  if state.layout.popup then
    state.layout.popup:unmount()

    for _, comp in ipairs({ state.layout, state.input, state.llm, state.history }) do
      comp.popup = nil
    end
  else
    if state.input.popup then
      state.input.popup:unmount()
      state.input.popup = nil
      return
    else
      LOG:TRACE("Close Split window")
      pcall(vim.api.nvim_win_close, state.llm.winid, true)
      vim.api.nvim_buf_delete(state.llm.bufnr, { force = true })
      if state.history.popup then
        state.history.popup:unmount()
        state.history.popup = nil
      end
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

      filename = string.format("%s/%s-%s.json", conf.configs.history_path, _filename, os.date("%Y%m%d%H%api%S"))
    end
    local file = io.open(filename, "w")
    if file then
      file:write(vim.fn.json_encode(state.session[state.session.filename]))
      file:close()
    end
  end
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

function api.FlexibleWindow(str, enter_flexible_win, user_opts)
  local text = vim.split(str, "\n")
  local width = 0
  local height = #text
  local max_win_width = math.floor(vim.o.columns * 0.7)
  local max_win_height = math.floor(vim.o.lines * 0.7)
  for i, line in ipairs(text) do
    if vim.api.nvim_strwidth(line) > width then
      width = vim.api.nvim_strwidth(line)
      if width > max_win_width then
        height = height + 1
      end
    end
    text[i] = "" .. line
  end

  local win_width = math.min(width, max_win_width)
  local win_height = math.min(height, max_win_height)
  if win_width < 1 or win_height < 1 then
    LOG:ERROR(
      string.format("Unable to create a window with width %s and height %s.", tostring(win_width), tostring(win_height))
    )
    return nil
  end

  local opts = {
    relative = "cursor",
    position = {
      row = -2,
      col = 0,
    },
    size = {
      height = win_height,
      width = win_width,
    },
    enter = enter_flexible_win,
    focusable = true,
    zindex = 50,
    border = {
      style = "rounded",
    },
    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  }

  opts = vim.tbl_deep_extend("force", opts, user_opts or {})
  local flexible_box = Popup(opts)

  vim.api.nvim_buf_set_lines(flexible_box.bufnr, 0, -1, false, text)
  return flexible_box
end

function api.GetUrlOutput(
  messages,
  fetch_key,
  url,
  model,
  api_type,
  args,
  parse_handler,
  stdout_handler,
  stderr_handler,
  exit_handler
)
  local wait_box_opts = api.wait_ui_opts()
  local wait_box = Popup(wait_box_opts)

  local waiting_state = {
    box = wait_box,
    box_opts = wait_box_opts,
    bufnr = wait_box.bufnr,
    winid = wait_box.winid,
    finish = false,
  }

  waiting_state.box:mount()
  api.show_spinner(waiting_state)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")

  if fetch_key ~= nil then
    LLM_KEY = fetch_key()
  end

  if url == nil then
    url = conf.configs.url
  end

  local MODEL = conf.configs.model
  if model ~= nil then
    MODEL = model
  end

  local body = nil
  local assistant_output = ""
  local parse = nil
  local authorization = "Authorization: Bearer " .. LLM_KEY

  if parse_handler then
    parse = function(chunk)
      local success, err = pcall(function()
        assistant_output = parse_handler(chunk)
      end)

      if success then
        return assistant_output
      else
        LOG:TRACE(vim.inspect(chunk))
        LOG:ERROR("Error occurred:" .. err)
        return ""
      end
    end
  elseif api_type then
    if api_type == "workers-ai" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.result.response
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif api_type == "zhipu" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.choices[1].message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif api_type == "openai" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.choices[1].message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif api_type == "ollama" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    end
  elseif conf.configs.parse_handler then
    parse = function(chunk)
      local success, err = pcall(function()
        assistant_output = conf.configs.parse_handler(chunk)
      end)

      if success then
        return assistant_output
      else
        LOG:TRACE(vim.inspect(chunk))
        LOG:ERROR("Error occurred:" .. err)
        return ""
      end
    end
  elseif conf.configs.api_type then
    if conf.configs.api_type == "workers-ai" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.result.response
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif conf.configs.api_type == "zhipu" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.choices[1].message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif conf.configs.api_type == "openai" then
      parse = function(chunk)
        LOG:TRACE(vim.inspect(chunk))
        local success, err = pcall(function()
          assistant_output = chunk.choices[1].message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    elseif conf.configs.api_type == "ollama" then
      parse = function(chunk)
        local success, err = pcall(function()
          assistant_output = chunk.message.content
        end)

        if success then
          return assistant_output
        else
          LOG:TRACE(vim.inspect(chunk))
          LOG:ERROR("Error occurred:" .. err)
          return ""
        end
      end
    end
  end

  local _args = nil
  if url ~= nil then
    body = {
      model = MODEL,
      max_tokens = conf.configs.max_tokens,
      messages = messages,
      stream = false,
    }

    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if args == nil then
      _args = {
        url,
        "-N",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        authorization,
        "-d",
        vim.fn.json_encode(body),
      }
    else
      local env = {
        url = url,
        LLM_KEY = LLM_KEY,
        body = body,
        authorization = authorization,
      }

      setmetatable(env, { __index = _G })
      _args = api.GetUserRequestArgs(args, env)
    end

    if parse == nil then
      -- if url is set, but not set parse_handler, parse will be `zhipu` by default
      parse = function(chunk)
        assistant_output = chunk.choices[1].message.content
        return assistant_output
      end
    end
  else
    body = {
      max_tokens = conf.configs.max_tokens,
      messages = messages,
    }
    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if args == nil then
      _args = {
        string.format("https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s", ACCOUNT, MODEL),
        "-N",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        authorization,
        "-d",
        vim.fn.json_encode(body),
      }
    else
      local env = {
        ACCOUNT = ACCOUNT,
        MODEL = MODEL,
        LLM_KEY = LLM_KEY,
        body = body,
        authorization = authorization,
      }

      setmetatable(env, { __index = _G })
      _args = api.GetUserRequestArgs(args, env)
    end

    if parse == nil then
      -- if url is not set, parse will be `workers-ai` by default
      parse = function(chunk)
        assistant_output = chunk.response
        return assistant_output
      end
    end
  end

  job
    :new({
      command = "curl",
      args = _args,
      on_stdout = vim.schedule_wrap(function(_, data)
        local str = api.trim_leading_whitespace(data)
        if str:sub(1, 1) ~= "{" then
          return
        end
        local success, result = pcall(vim.json.decode, str)
        if success then
          assistant_output = parse(result)
        else
          LOG:ERROR("Error occurred:" .. result)
        end
      end),
      on_exit = vim.schedule_wrap(function()
        table.insert(messages, { role = "assistant", content = assistant_output })
        waiting_state.box:unmount()
        waiting_state.finish = true
        if exit_handler ~= nil then
          local callback_func = vim.schedule_wrap(function()
            exit_handler(assistant_output)
          end)
          callback_func()
        end
      end),
    })
    :start()
end

return api
