Ask = {
  handler = tools.disposable_ask_handler,
  opts = {
    position = {
      row = 2,
      col = 0,
    },
    title = " Ask ",
    inline_assistant = true,
    language = "Chinese",

    -- [optinal] set your llm model
    url = "https://api.chatanywhere.tech/v1/chat/completions",
    model = "gpt-4o-mini",
    api_type = "openai",
    fetch_key = function()
      return vim.env.CHAT_ANYWHERE_KEY
    end,

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
