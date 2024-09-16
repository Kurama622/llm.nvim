vim.api.nvim_create_user_command("LLMSessionToggle", function()
  require("llm.session").NewSession()
end, {})

vim.api.nvim_create_user_command("LLMSelectedTextHandler", function(args)
  require("llm.session").LLMSelectedTextHandler(args.fargs[1])
end, { nargs = 1 })

vim.api.nvim_create_user_command("LLMAppHandler", function(args)
  require("llm.app").LLMAppHandler(args.fargs[1])
end, { nargs = 1 })
