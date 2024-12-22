local M = {}
local luv = vim.loop

local function get_win_width()
  return vim.o.columns
end

-- default box width
local input_box_width = math.floor(get_win_width() * 0.7)
local input_box_start = math.floor(get_win_width() * 0.15)

local history_box_width = 27
local output_box_start = input_box_start

local output_box_width = math.floor(get_win_width() * 0.7 - history_box_width - 2)
local history_box_start = math.floor(output_box_start + get_win_width() * 0.7 - history_box_width)

local HOME = ""

local uname = luv.os_uname()
if uname.sysname == "Linux" or uname.sysname == "Darwin" then
  HOME = os.getenv("HOME")
else
  HOME = os.getenv("USERPROFILE")
end

M._ = {}

M._.input_box_opts = {
  relative = "editor",
  position = {
    row = "85%",
    col = input_box_start,
  },
  size = {
    height = "5%",
    width = input_box_width,
  },
  enter = true,
  focusable = true,
  zindex = 50,
  border = {
    style = "rounded",
    text = {
      top = " Enter Your Question ",
      top_align = "center",
    },
  },
  win_options = {
    winblend = 0,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
}

M._.output_box_opts = {
  relative = "editor",
  position = {
    row = "35%",
    col = output_box_start,
  },
  size = {
    height = "65%",
    width = output_box_width,
  },
  enter = true,
  focusable = true,
  zindex = 20,
  border = {
    style = "rounded",
    text = {
      top = " Preview ",
      top_align = "center",
    },
  },
  win_options = {
    winblend = 0,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
}

M._.history_box_opts = {
  relative = "editor",
  position = {
    row = "35%",
    col = history_box_start,
  },
  size = {
    height = "65%",
    width = history_box_width,
  },
  zindex = 70,
  enter = false,
  focusable = false,
  border = {
    style = "rounded",
    text = {
      top = " History ",
      top_align = "center",
    },
  },
  win_options = {
    winblend = 0,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
}

M._.popwin_opts = {
  relative = "cursor",
  position = {
    row = -7,
    col = 10,
  },
  size = {
    height = 10,
    width = "60%",
  },
  enter = true,
  focusable = true,
  zindex = 50,
  border = {
    style = "rounded",
    text = {
      top = " Explain ",
      top_align = "center",
    },
  },
  win_options = {
    winblend = 0,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
}

-- support icons
M.prefix = {
  user = { text = "", hl = "" },
  assistant = { text = "", hl = "" },
}

-- default configs
M.configs = {
  prompt = "",
  max_tokens = 1024,
  model = "@cf/qwen/qwen1.5-14b-chat-awq",
  url = nil,
  api_type = nil,
  fetch_key = nil,
  streaming_handler = nil,
  temperature = nil,
  top_p = nil,
  style = "float", -- right | left | above | below | float
  spinner = { text = { "-", "\\", "|", "/" }, hl = "Title" },

  prefix = {
    user = { text = "## User \n", hl = "Title" },
    assistant = { text = "## Assistant \n", hl = "Added" },
  },

  history_path = HOME .. "/.local/state/nvim/llm-history",
  max_history_files = 15,
  max_history_name_length = 10,
  save_session = true,

  input_box_opts = M._.input_box_opts,
  output_box_opts = M._.output_box_opts,
  history_box_opts = M._.history_box_opts,

  popwin_opts = M._.popwin_opts,

  app_handler = {},

  display = {
    diff = {
      layout = "vertical", -- vertical|horizontal split for default provider
      opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
      provider = "default", -- default|mini_diff
    },
  },
  -- stylua: ignore
  keys = {
    -- The keyboard mapping for the input window.
    ["Input:Submit"]  = { mode = "i", key = "<C-g>" },
    ["Input:Cancel"]  = { mode = "i", key = "<C-c>" },
    ["Input:Resend"]  = { mode = "i", key = "<C-r>" },

    -- only works when "save_session = true"
    ["Input:HistoryNext"]  = { mode = "i", key = "<C-j>" },
    ["Input:HistoryPrev"]  = { mode = "i", key = "<C-k>" },

    -- The keyboard mapping for the output window in "split" style.
    ["Output:Ask"]  = { mode = "n", key = "i" },
    ["Output:Cancel"]  = { mode = "n", key = "<C-c>" },
    ["Output:Resend"]  = { mode = "n", key = "<C-r>" },

    -- The keyboard mapping for the output and input windows in "float" style.
    ["Session:Toggle"] = { mode = "n", key = "<leader>ac" },
    ["Session:Close"]  = { mode = "n", key = "<esc>" },
  },
}

M.session = {
  messages = {},
  status = -1,
}

function M.setup(opts)
  M.configs = vim.tbl_deep_extend("force", M.configs, opts or {})
  table.insert(M.session.messages, { role = "system", content = M.configs.prompt })

  if not M.configs.save_session then
    M.configs.output_box_opts.size.width = M.configs.input_box_opts.size.width
  else
    local dir = io.open(M.configs.history_path, "rb")
    if dir then
      dir:close()
    else
      vim.fn.mkdir(M.configs.history_path, "p")
    end
  end

  M._.input_box_opts = M.configs.input_box_opts
  M._.output_box_opts = M.configs.output_box_opts
  M._.history_box_opts = M.configs.history_box_opts

  M.prefix.user = M.configs.prefix.user
  M.prefix.assistant = M.configs.prefix.assistant
end

return M
