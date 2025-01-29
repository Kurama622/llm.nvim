Completion = {
  handler = tools.completion_handler,
  opts = {
    --------------------------------
    ---         ollama
    --------------------------------
    url = "http://localhost:11434/v1/completions",
    model = "qwen2.5-coder:1.5b",
    api_type = "ollama",
    ---------- end ollama ----------

    --------------------------------
    ---         deepseek
    --------------------------------
    -- url = "https://api.deepseek.com/beta/completions",
    -- model = "deepseek-chat",
    -- api_type = "deepseek",
    -- fetch_key = function()
    --   return "your api key"
    -- end,
    --------- end deepseek ---------

    n_completions = 3,
    context_window = 512,
    max_tokens = 256,
    ignore_filetypes = {},
    auto_trigger = true,
    style = "virtual_text", -- nvim-cmp or blink.cmp
    timeout = 10, -- max request time
    throttle = 1000, -- only send the request every x milliseconds, use 0 to disable throttle.
    -- debounce the request in x milliseconds, set to 0 to disable debounce
    debounce = 400,

    --------------------------------
    ---   just for virtual_text
    --------------------------------
    keymap = {
      virtual_text = {
        accept = {
          mode = "i",
          keys = "<A-a>",
        },
        next = {
          mode = "i",
          keys = "<A-n>",
        },
        prev = {
          mode = "i",
          keys = "<A-p>",
        },
        toggle = {
          mode = "n",
          keys = "<leader>cp",
        },
      },
    },
  },
},

