local M = {}
local fio = require("llm.common.file_io")
local luv = vim.loop

local function get_win_width()
  return vim.o.columns
end

local HOME = ""

local uname = luv.os_uname()
if uname.sysname == "Linux" or uname.sysname == "Darwin" then
  HOME = os.getenv("HOME")
else
  HOME = os.getenv("USERPROFILE")
end

M._ = {}
M._.chat_ui_opts = {
  relative = "editor",
  position = "50%",
  size = {
    width = "80%",
    height = "80%",
  },
  input = {
    float = {
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
      buf_options = {
        filetype = "llm",
      },
      size = { height = "15%", width = "100%" },
      order = 3,
    },
    split = {
      position = {
        row = "80%",
        col = "50%",
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
      buf_options = {
        filetype = "llm",
      },
      size = { height = "10%", width = "80%" },
    },
  },
  output = {
    float = {
      enter = true,
      focusable = true,
      zindex = 50,
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
        spell = false,
        wrap = true,
      },
      buf_options = {
        filetype = "llm",
      },
      size = { height = "85%", width = "80%" },
      order = 1,
    },
    split = {
      size = "40%",
      buf_options = {
        filetype = "llm",
        buftype = "nofile",
      },
      win_options = {
        number = false,
        relativenumber = false,
        signcolumn = "no",
        spell = false,
        wrap = true,
        linebreak = false,
      },
    },
  },
  history = {
    float = {
      zindex = 50,
      enter = false,
      focusable = false,
      max_width = 20,
      border = {
        style = "rounded",
        text = {
          top = " History ",
          top_align = "center",
        },
      },
      win_options = {
        winblend = 0,
        winhighlight = "Normal:LlmWhiteNormal,FloatBorder:FloatBorder",
      },
      size = { height = "85%", width = "20%" },
      order = 2,
    },
    split = {
      cmd = "fzf --cycle",
      enable_fzf_focus_print = true,
      position = "50%",
      win_options = {
        winblend = 0,
        winhighlight = "Normal:LlmWhiteNormal,FloatBorder:FloatBorder",
      },
      select = {
        border = {
          style = "rounded",
          text = {
            top = " History ",
            top_align = "center",
          },
        },
      },
      size = "60%",
      order = 1,
    },
  },
  models = {
    float = {
      zindex = 50,
      enter = false,
      focusable = false,
      max_width = 20,
      border = {
        style = "rounded",
        text = {
          top = " Models ",
          top_align = "center",
        },
      },
      win_options = {
        winblend = 0,
        winhighlight = "Normal:LlmWhiteNormal,FloatBorder:FloatBorder",
      },
      size = { height = "85%", width = "20%" },
      order = 2,
    },
    split = {
      zindex = 50,
      enter = true,
      focusable = true,
      max_width = 20,
      border = {
        style = "rounded",
        text = {
          top = " Models ",
          top_align = "center",
        },
      },
      win_options = {
        winblend = 0,
        winhighlight = "Normal:LlmWhiteNormal,FloatBorder:FloatBorder",
      },
      size = { height = "30%", width = "30%" },
      order = 1,
    },
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
    spell = false,
    linebreak = false,
    wrap = true,
  },
  buf_options = {
    filetype = "llm",
    buftype = "nofile",
  },
  move = {
    left = {
      mode = "n",
      keys = "<left>",
      distance = 5,
    },
    right = {
      mode = "n",
      keys = "<right>",
      distance = 5,
    },
    up = {
      mode = "n",
      keys = "<up>",
      distance = 2,
    },
    down = {
      mode = "n",
      keys = "<down>",
      distance = 2,
    },
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
  timeout = 120,
  max_tokens = nil,
  model = nil,
  url = nil,
  api_type = nil,
  fetch_key = nil,
  streaming_handler = nil,
  temperature = nil,
  top_p = nil,
  enable_thinking = nil,
  thinking_budget = nil,
  schema = nil,
  functions_tbl = nil,
  style = "float", -- right | left | top | bottom | float
  spinner = { text = { "-", "\\", "|", "/" }, hl = "Title" },

  prefix = {
    user = { text = "## User \n", hl = "Title" },
    assistant = { text = "## Assistant \n", hl = "Added" },
  },

  history_path = HOME .. "/.local/state/nvim/llm-history",
  max_history_files = 15,
  max_history_name_length = 10,
  save_session = true,

  chat_ui_opts = M._.chat_ui_opts,

  popwin_opts = M._.popwin_opts,

  app_handler = {},
  enable_trace = false,
  log_level = 1,

  display = {
    diff = {
      layout = "vertical", -- vertical|horizontal split for default provider
      opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
      provider = "default", -- default|mini_diff
      disable_diagnostic = false,
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

    -- only works when models is not empty
    ["Input:ModelsNext"]  = { mode = "i", key = "<C-S-j>" },
    ["Input:ModelsPrev"]  = { mode = "i", key = "<C-S-k>" },

    -- The keyboard mapping for the output window in "split" style.
    ["Output:Ask"]  = { mode = "n", key = "i" },
    ["Output:Cancel"]  = { mode = "n", key = "<C-c>" },
    ["Output:Resend"]  = { mode = "n", key = "<C-r>" },

    -- The keyboard mapping for the output and input windows in "float" style.
    ["Session:Toggle"] = { mode = "n", key = "<leader>ac" },
    ["Session:Close"]  = { mode = "n", key = "<esc>" },
    ["Session:History"]  = { mode = "n", key = "<C-h>" },
    ["Session:Models"]  = { mode = "n", key = "<C-m>" },

    -- Scroll
    ["PageUp"]            = { mode = {"i","n"}, key = "<C-b>" },
    ["PageDown"]          = { mode = {"i","n"}, key = "<C-f>" },
    ["HalfPageUp"]        = { mode = {"i","n"}, key = "<C-u>" },
    ["HalfPageDown"]      = { mode = {"i","n"}, key = "<C-d>" },
    ["JumpToTop"]         = { mode = "n", key = "gg" },
    ["JumpToBottom"]      = { mode = "n", key = "G" }
  },
}

M.session = {
  messages = {},
  status = -1,
}

function M.setup(opts)
  M.configs = vim.tbl_deep_extend("force", M.configs, opts or {})
  table.insert(M.session.messages, { role = "system", content = M.configs.prompt })

  require("llm.common.log"):setup(M.configs.enable_trace, M.configs.log_level)

  if M.configs.save_session then
    fio.CreateDir(M.configs.history_path)
  end

  M._.chat_ui_opts = M.configs.chat_ui_opts

  M.configs.popwin_opts.border.text.top_user = M.configs.popwin_opts.border.text.top
  M.configs.popwin_opts.border.text.top_builtin = " [<d>: display diff, <y>: copy code] "
  M.prefix.user = M.configs.prefix.user
  M.prefix.assistant = M.configs.prefix.assistant
end

return M
