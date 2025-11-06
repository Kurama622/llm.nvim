OptimCompare = {
  handler = tools.action_handler,
  opts = {
    fetch_key = "<your api key>",
    url = "https://models.inference.ai.azure.com/chat/completions",
    model = "gpt-4o-mini",
    api_type = "openai",
    language = "Chinese",
    diagnostic = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR },
  },
},
