vim.api.nvim_create_user_command("LLMSessionToggle", function()
  require("llm.session").NewSession()
end, {})

vim.api.nvim_create_user_command("LLMUserDefineOp", function(args)
  require("llm.session").LLMUserDefineOp(args.fargs[1])
end, { nargs = 1 })
