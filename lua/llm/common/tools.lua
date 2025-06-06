vim.notify('"llm.common.tools" is deprecated, please use require("llm.tools") instead!', vim.log.levels.WARN, {
  title = "llm.nvim",
})
return {
  action_handler = require("llm.tools.action").handler,
  completion_handler = require("llm.tools.completion").handler,
  curl_request_handler = require("llm.tools.curl_request").handler,
  flexi_handler = require("llm.tools.flexible").handler,
  qa_handler = require("llm.tools.qa").handler,
  side_by_side_handler = require("llm.tools.side_by_side").handler,
}
