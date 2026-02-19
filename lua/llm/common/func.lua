vim.notify(
  '"llm.common.func" is deprecated, please use require("llm.common.api") instead!',
  vim.log.levels.WARN,
  {
    title = "llm.nvim",
  }
)
return require("llm.common.api")
