Ask = {
  handler = tools.disposable_ask_handler,
  opts = {
    position = {
      row = 2,
      col = 0,
    },
    title = " Ask ",
    inline_assistant = true,
    -- display diff
    display = {
      mapping = {
        mode = "n",
        keys = { "d" },
      },
      action = nil,
    },
    -- accept diff
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    -- reject diff
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    -- close diff
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
},
