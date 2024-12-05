local seamless = {}

-- Reference: https://github.com/SmiteshP/nvim-navbuddy/blob/master/lua/nvim-navbuddy/ui.lua
-- Author: @SmiteshP
-- Updated by @Kurama622
function seamless.get_border_chars(style, section)
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

return seamless
