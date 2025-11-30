local M = {
  action_handler = function()
    return require("llm.tools.action").handler
  end,
  completion_handler = function()
    return require("llm.tools.completion").handler
  end,
  flexi_handler = function()
    return require("llm.tools.flexible").handler
  end,
  qa_handler = function()
    return require("llm.tools.qa").handler
  end,
  images_handler = function()
    return require("llm.tools.images").handler
  end,
  side_by_side_handler = function()
    return require("llm.tools.side_by_side").handler
  end,
  disposable_ask_handler = function()
    return require("llm.tools.disposable_ask").handler
  end,
  attach_to_chat_handler = function()
    return require("llm.tools.attach_to_chat").handler
  end,
  curl_request_handler = function(...)
    return require("llm.tools.curl_request").handler(...)
  end,
}
setmetatable(M, {
  __call = function(t, key, ...)
    if type(key) == "function" then
      local fn = key()
      if type(fn) == "function" then
        return fn(...)
      else
        return fn
      end
    end
    if type(key) == "string" then
      return t[key]()(...)
    end
  end,
})
return M
