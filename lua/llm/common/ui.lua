local Popup = require("nui.popup")
local conf = require("llm.config")
local LOG = require("llm.common.log")
local F = require("llm.common.api")

local ui = {}

local llm_spinner_ns = vim.api.nvim_create_namespace("llm_spinner_extmark")

-- Reference: https://github.com/SmiteshP/nvim-navbuddy/blob/master/lua/nvim-navbuddy/ui.lua
-- Author: @SmiteshP
-- Updated by @Kurama622
function ui.seamless(style, section)
  if style ~= "single" and style ~= "rounded" and style ~= "double" and style ~= "solid" then
    return style
  end

  -- stylua: ignore
  local border_chars = {
    top_left = {
      single  = "┌",
      rounded = "╭",
      double  = "╔",
      solid   = "▛",
    },
    top = {
      single  = "─",
      rounded = "─",
      double  = "═",
      solid   = "▀",
    },
    top_right = {
      single  = "┐",
      rounded = "╮",
      double  = "╗",
      solid   = "▜",
    },
    right = {
      single  = "│",
      rounded = "│",
      double  = "║",
      solid   = "▐",
    },
    bottom_right = {
      single  = "┘",
      rounded = "╯",
      double  = "╝",
      solid   = "▟",
    },
    bottom = {
      single  = "─",
      rounded = "─",
      double  = "═",
      solid   = "▄",
    },
    bottom_left = {
      single  = "└",
      rounded = "╰",
      double  = "╚",
      solid   = "▙",
    },
    left = {
      single  = "│",
      rounded = "│",
      double  = "║",
      solid   = "▌",
    },
    top_T = {
      single  = "┬",
      rounded = "┬",
      double  = "╦",
      solid   = "▛",
    },
    bottom_T = {
      single  = "┴",
      rounded = "┴",
      double  = "╩",
      solid   = "▙",
    },
    left_T = {
      single  = "├",
      rounded = "├",
      double  = "╠",
      solid   = "▛",
    },
    right_T = {
      single  = "┤",
      rounded = "┤",
      double  = "╣",
      solid   = "▜",
    },
    blank = "",
  }

  local border_chars_map = {
    left = {
      border_chars.top_left[style],
      border_chars.top[style],
      border_chars.top[style],
      border_chars.blank,
      border_chars.bottom[style],
      border_chars.bottom[style],
      border_chars.bottom_left[style],
      border_chars.left[style],
    },
    mid_vert = {
      border_chars.top_T[style],
      border_chars.top[style],
      border_chars.top[style],
      border_chars.blank,
      border_chars.bottom[style],
      border_chars.bottom[style],
      border_chars.bottom_T[style],
      border_chars.left[style],
    },
    right = {
      border_chars.top_T[style],
      border_chars.top[style],
      border_chars.top_right[style],
      border_chars.right[style],
      border_chars.bottom_right[style],
      border_chars.bottom[style],
      border_chars.bottom_T[style],
      border_chars.left[style],
    },

    -- style = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    top = {
      border_chars.top_left[style],
      border_chars.top[style],
      border_chars.top_right[style],
      border_chars.right[style],
      border_chars.right[style],
      border_chars.blank,
      border_chars.left[style],
      border_chars.left[style],
    },
    mid_horz = {
      border_chars.left_T[style],
      border_chars.top[style],
      border_chars.right_T[style],
      border_chars.right[style],
      border_chars.left[style],
      border_chars.blank,
      border_chars.right[style],
      border_chars.left[style],
    },
    bottom = {
      border_chars.left_T[style],
      border_chars.top[style],
      border_chars.right_T[style],
      border_chars.right[style],
      border_chars.bottom_right[style],
      border_chars.bottom[style],
      border_chars.bottom_left[style],
      border_chars.left[style],
    },
  }
  return border_chars_map[section]
end

function ui.FlexibleWindow(str, enter_flexible_win, user_opts)
  local text = vim.split(str, "\n")
  local width = 0
  local height = #text
  local max_win_width = math.floor(vim.o.columns * 0.7)
  local max_win_height = math.floor(vim.o.lines * 0.7)
  local len = {}
  for i, line in ipairs(text) do
    len[i] = vim.api.nvim_strwidth(line)
    if len[i] > width then
      width = len[i]
    end
  end

  local win_width = math.min(width, max_win_width)
  for _, item in ipairs(len) do
    if item > win_width then
      height = height + math.ceil(item / win_width - 1)
    end
  end
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
    zindex = 100,
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

function ui.wait_ui_opts(win_opts)
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

function ui.show_spinner(waiting_state)
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
      F.AddHighlight("spinner", waiting_state.bufnr, spinner_hl, 0, 0, 0, -1)

      frame = frame % #spinner_frames + 1
    end)
  )
end

function ui.display_spinner_extmark(opts)
  local spinner_frames = conf.configs.spinner.text
  local spinner_hl = conf.configs.spinner.hl
  local frame = 1
  opts.spinner_status = true

  local timer = vim.loop.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if vim.api.nvim_win_is_valid(opts.winid) then
        if opts.spinner_id ~= nil then
          vim.api.nvim_buf_del_extmark(opts.bufnr, llm_spinner_ns, opts.spinner_id)
        end
        if opts.spinner_status then
          opts.spinner_id =
            vim.api.nvim_buf_set_extmark(opts.bufnr, llm_spinner_ns, vim.api.nvim_buf_line_count(opts.bufnr) - 1, 0, {
              virt_text = { { spinner_frames[frame], spinner_hl } },
              virt_text_pos = "eol",
            })
        end
      end
      if not opts.spinner_status or not vim.api.nvim_win_is_valid(opts.winid) then
        timer:stop()
        return
      end

      frame = frame % #spinner_frames + 1
    end)
  )
end

function ui.clear_spinner_extmark(opts)
  if opts.spinner_status then
    opts.spinner_status = false
    if opts.spinner_id ~= nil and vim.api.nvim_win_is_valid(opts.winid) then
      vim.api.nvim_buf_del_extmark(opts.bufnr, llm_spinner_ns, opts.spinner_id)
    end
  end
end
return ui
