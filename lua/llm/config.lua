local M = {}

-- support icons
M.prefix = {
  user = { text = "", hl = "" },
  assistant = { text = "", hl = "" },
}

-- default configs
M.configs = {
  prompt = "",
  max_tokens = 512,
  model = "@cf/qwen/qwen1.5-14b-chat-awq",

  prefix = {
    user = { text = "## User \n", hl = "Title" },
    assistant = { text = "## Assistant \n", hl = "Added" },
  },

  history_path = "/tmp/history",
  input_box_opts = {
    relative = "editor",
    position = {
      row = "85%",
      col = 15,
    },
    size = {
      height = "5%",
      width = 120,
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
  },
  output_box_opts = {
    style = "float", -- right | left | above | below | float
    relative = "editor",
    position = {
      row = "35%",
      col = 15,
    },
    size = {
      height = "65%",
      width = 90,
    },
    enter = true,
    focusable = true,
    zindex = 20,
    border = {
      style = "rounded",
      text = {
        top = " LLM ",
        top_align = "center",
      },
    },
  },

  history_box_opts = {
    relative = "editor",
    position = {
      row = "35%",
      col = 108,
    },
    size = {
      height = "65%",
      width = 27,
    },
    zindex = 70,
    focusable = false,
    border = {
      style = "rounded",
      text = {
        top = " History ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  },

  popwin_opts = {
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
  },
  -- stylua: ignore
  keys = {
    -- The keyboard mapping for the input window.
    ["Input:Submit"]  = { mode = "i", key = "<C-g>" },
    ["Input:Cancel"]  = { mode = "i", key = "<C-c>" },
    ["Input:Resend"]  = { mode = "i", key = "<C-r>" },

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

  local file = io.open(M.configs.history_path, "rb")
  if file then
    file:close()
  else
    os.execute("mkdir -p " .. M.configs.history_path)
  end

  M.prefix.user = M.configs.prefix.user
  M.prefix.assistant = M.configs.prefix.assistant
end

return M
