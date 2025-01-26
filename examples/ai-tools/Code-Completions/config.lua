Completion = {
  handler = tools.completion_handler,
  opts = {
    url = "http://localhost:11434/v1/completions",
    model = "qwen2.5-coder:1.5b",
    api_type = "ollama",
    n_completions = 3,
    context_window = 512,
    max_tokens = 256,
    ignore_filetypes = {},
    auto_trigger = true,
    style = "virtual_text", -- nvim-cmp or blink.cmp
  },
},
