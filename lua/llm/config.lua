local M = {}

M.configs = {
  prompt = "",
  max_tokens = 512,
  model = "@cf/qwen/qwen1.5-14b-chat-awq",

  input_box_opts = {
    relative = "editor",
    position = {
      row = "85%",
      col = "50%",
    },
    size = {
      width = "70%",
      height = "5%",
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
    relative = "win",
    position = {
      row = "35%",
      col = "50%",
    },
    size = {
      width = "70%",
      height = "65%",
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
    popwin_opts = {
      relative = "cursor",
      position = {
        row = -5,
        col = 10,
      },
      size = {
        width = "60%",
        height = 10,
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

  -- for _, mapping in ipairs(conf.keys) do
  --   vim.keymap.set(mapping.mode, mapping.key, mapping.func)
  -- end
end

return M
