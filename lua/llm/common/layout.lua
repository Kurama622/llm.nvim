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

--- @param size1 {row: number, col: number}
--- @param size2 {row: number, col: number}
--- @return {dir: 'row'|'col'|nil, size: number}
local function get_sublayout_opts(size1, size2)
  local opts = { nil, 0 }
  if size1.row == size2.row and size1.col + size2.col == 1 then
    opts = { "col", size1.row }
  elseif size1.col == size2.col and size1.row + size2.row == 1 then
    opts = { "row", size1.col }
  end
  return opts
end

local _not = {
  row = "col",
  col = "row",
}

---create chat ui
---@param layout_opts table|nil
---@param popup_input_opts table|nil
---@param popup_output_opts table|nil
---@param popup_other_opts table|nil
function _layout.chat_ui(layout_opts, popup_input_opts, popup_output_opts, popup_other_opts)
  local layout = layout_opts or conf.configs.chat_ui_opts
  local input = popup_input_opts or conf.configs.chat_ui_opts.input
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
    size.row = reformat_size(size.row)
    size.col = reformat_size(size.col)
  end
  if popup_input_opts == nil and popup_output_opts == nil and popup_other_opts == nil and conf.configs.save_session then
    local _dir, _size = nil, nil
    _dir, _size = unpack(get_sublayout_opts(input.size, output.size))
    if _dir then
      state.layout.popup = Layout(
        { relative = layout.relative, position = layout.position, size = layout.size },
        Layout.Box({
          Layout.Box({
            Layout.Box(state.llm.popup, { size = output.size[_dir] }),
            Layout.Box(state.input.popup, { size = input.size[_dir], grow = 1 }),
          }, { dir = _not[_dir], size = _size }),
          Layout.Box(state.history.popup, { size = other.size[_not[_dir]] }),
        }, { dir = _dir })
      )
      state.layout.info = {
        sublayout = {
          dir = _not[_dir],
          box = { llm = output.size[_dir], input = input.size[_dir] },
          size = _size,
        },
        popup = {
          dir = _dir,
          box = { history = other.size[_not[_dir]] },
        },
      }
      return
    end

    _dir, _size = unpack(get_sublayout_opts(output.size, other.size))
    if _dir then
      state.layout.popup = Layout(
        { relative = layout.relative, position = layout.position, size = layout.size },
        Layout.Box({
          Layout.Box({
            Layout.Box(state.llm.popup, { size = output.size[_dir] }),
            Layout.Box(state.history.popup, { size = other.size[_dir], grow = 1 }),
          }, { dir = _not[_dir], size = _size }),
          Layout.Box(state.input.popup, { size = input.size[_not[_dir]] }),
        }, { dir = _dir })
      )
      state.layout.info = {
        sublayout = {
          dir = _not[_dir],
          box = { llm = output.size[_dir], history = other.size[_dir] },
          size = _size,
        },
        popup = {
          dir = _dir,
          box = { input = input.size[_not[_dir]] },
        },
      }
      return
    end

    _dir, _size = unpack(get_sublayout_opts(input.size, other.size))
    if _dir then
      state.layout.popup = Layout(
        { relative = layout.relative, position = layout.position, size = layout.size },
        Layout.Box({
          Layout.Box({
            Layout.Box(state.input.popup, { size = input.size[_dir] }),
            Layout.Box(state.history.popup, { size = other.size[_dir], grow = 1 }),
          }, { dir = _not[_dir], size = _size }),
          Layout.Box(state.llm.popup, { size = output.size[_not[_dir]] }),
        }, { dir = _dir })
      )
      state.layout.info = {
        sublayout = {
          dir = _not[_dir],
          box = { input = input.size[_dir], history = other.size[_dir] },
          size = _size,
        },
        popup = {
          dir = _dir,
          box = { llm = output.size[_not[_dir]] },
        },
      }
      return
    end
  else
    if input.size.col == output.size.col then
      state.layout.popup = Layout(
        { relative = layout.relative, position = layout.position, size = layout.size },
        Layout.Box({
          Layout.Box(state.llm.popup, { size = output.size.row }),
          Layout.Box(state.input.popup, { size = input.size.row }),
        }, { dir = "col" })
      )
    elseif input.size.row == output.size.row then
      state.layout.popup = Layout(
        { relative = layout.relative, position = layout.position, size = layout.size },
        Layout.Box({
          Layout.Box(state.llm.popup, { size = output.size.col }),
          Layout.Box(state.input.popup, { size = input.size.col }),
        }, { dir = "row" })
      )
    end
  end
end

return _layout
