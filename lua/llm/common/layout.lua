local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Menu = require("nui.menu")
local conf = require("llm.config")
local state = require("llm.state")
local F = require("llm.common.func")
local LOG = require("llm.common.log")

local _layout = {}

local function string2number(percent)
  return tonumber((string.gsub(percent, "%%", ""))) / 100
end
local function reformat_size(size)
  if type(size) == "string" then
    size = string2number(size)
  end
  return size
end

--- @param size1 {height: number, width: number}
--- @param size2 {height: number, width: number}
--- @return string|nil
--- @return number
local function get_sublayout_opts(size1, size2)
  local opts = { nil, 0 }
  if size1.height == size2.height and size1.width + size2.width == 1 then
    opts = { "width", size1.height }
  elseif size1.width == size2.width and size1.height + size2.height == 1 then
    opts = { "height", size1.width }
  end
  return unpack(opts)
end

local _not = {
  height = "width",
  width = "height",
}

local _dir = {
  height = "row",
  width = "col",
}

---create chat ui
---@param layout_opts table|nil
---@param popup_input_opts table|nil
---@param popup_output_opts table|nil
---@param popup_other_opts table|nil
function _layout.chat_ui(layout_opts, popup_input_opts, popup_output_opts, popup_other_opts)
  local layout = layout_opts or conf.configs.chat_ui_opts
  local input = popup_input_opts or conf.configs.chat_ui_opts.input.float
  local output = popup_output_opts or conf.configs.chat_ui_opts.output
  local other = popup_other_opts or conf.configs.chat_ui_opts.history

  state.input.popup = Popup({
    enter = input.enter,
    focusable = input.focusable,
    zindex = input.zindex,
    border = input.border,
    win_options = input.win_options,
  })
  state.llm.popup = Popup({
    enter = output.enter,
    focusable = output.focusable,
    zindex = output.zindex,
    border = output.border,
    win_options = output.win_options,
  })
  if popup_other_opts then
    state.other.popup = Popup({
      enter = other.enter,
      focusable = other.focusable,
      zindex = other.zindex,
      border = other.border,
      win_options = other.win_options,
    })
  else
    state.history.popup = Menu({
      enter = other.enter,
      focusable = other.focusable,
      zindex = other.zindex,
      border = other.border,
      win_options = other.win_options,
    }, {
      lines = (function()
        local items = F.ListFilesInPath()
        state.history.list = { Menu.item("current") }
        for _, item in ipairs(items) do
          table.insert(state.history.list, Menu.item(item))
        end
        return state.history.list
      end)(),
      max_width = other.max_width,
      keymap = {
        focus_next = { "j", "<Down>", "<Tab>" },
        focus_prev = { "k", "<Up>", "<S-Tab>" },
        submit = { "<CR>", "<Space>" },
      },
      on_change = function(item)
        if item.text == "current" then
          state.session.filename = item.text
          if not state.session[item.text] then
            state.session[item.text] = F.DeepCopy(conf.session.messages)
          end
          F.RefreshLLMText(state.session[item.text])
        else
          local sess_file = string.format("%s/%s", conf.configs.history_path, item.text)
          state.session.filename = item.text
          if not state.session[item.text] then
            local file = io.open(sess_file, "r")
            if file then
              local messages = vim.fn.json_decode(file:read())
              state.session[item.text] = messages
              file:close()
            end
          end
          F.RefreshLLMText(state.session[item.text])
        end
      end,
      on_submit = function(item)
        LOG:TRACE("Menu Submitted: " .. item.text)
      end,
    })
  end
  for _, size in ipairs({ input.size, output.size, other.size }) do
    size.height = reformat_size(size.height)
    size.width = reformat_size(size.width)
  end
  if popup_input_opts == nil and popup_output_opts == nil and popup_other_opts == nil and conf.configs.save_session then
    local _align, _size = nil, nil
    _align, _size = get_sublayout_opts(input.size, output.size)
    if _align then
      if output.order < input.order then
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.llm.popup, { size = output.size[_align] }),
              Layout.Box(state.input.popup, { size = input.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.history.popup, { size = other.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      else
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.input.popup, { size = input.size[_align] }),
              Layout.Box(state.llm.popup, { size = output.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.history.popup, { size = other.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      end
      return
    end

    _align, _size = get_sublayout_opts(output.size, other.size)
    if _align then
      if output.order < other.order then
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.llm.popup, { size = output.size[_align] }),
              Layout.Box(state.history.popup, { size = other.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.input.popup, { size = input.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      else
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.history.popup, { size = other.size[_align] }),
              Layout.Box(state.llm.popup, { size = output.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.input.popup, { size = input.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      end
      return
    end

    _align, _size = get_sublayout_opts(input.size, other.size)
    if _align then
      if input.order < other.order then
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.input.popup, { size = input.size[_align] }),
              Layout.Box(state.history.popup, { size = other.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.llm.popup, { size = output.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      else
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box({
              Layout.Box(state.history.popup, { size = other.size[_align] }),
              Layout.Box(state.input.popup, { size = input.size[_align], grow = 1 }),
            }, { dir = _dir[_not[_align]], size = _size }),
            Layout.Box(state.llm.popup, { size = output.size[_not[_align]] }),
          }, { dir = _dir[_align] })
        )
      end
      return
    end
  else
    if input.size.col == output.size.col then
      if output.order < input.order then
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box(state.llm.popup, { size = output.size.height }),
            Layout.Box(state.input.popup, { size = input.size.height }),
          }, { dir = "col" })
        )
      else
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box(state.input.popup, { size = input.size.height }),
            Layout.Box(state.llm.popup, { size = output.size.height }),
          }, { dir = "col" })
        )
      end
    elseif input.size.row == output.size.row then
      if output.order < input.order then
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box(state.llm.popup, { size = output.size.width }),
            Layout.Box(state.input.popup, { size = input.size.width }),
          }, { dir = "row" })
        )
      else
        state.layout.popup = Layout(
          { relative = layout.relative, position = layout.position, size = layout.size },
          Layout.Box({
            Layout.Box(state.input.popup, { size = input.size.width }),
            Layout.Box(state.llm.popup, { size = output.size.width }),
          }, { dir = "row" })
        )
      end
    end
  end
end

return _layout
