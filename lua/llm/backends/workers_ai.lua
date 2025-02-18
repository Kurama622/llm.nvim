local LOG = require("llm.common.log")
local F = require("llm.common.api")
local workers_ai = {}

function workers_ai.StreamingHandler(chunk, context)
  if not chunk then
    return context.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    context.line = context.line .. chunk
  else
    context.line = context.line .. chunk
    local json_str = context.line:sub(7, -1)
    local status, data = pcall(vim.fn.json_decode, json_str)

    if not status then
      LOG:TRACE("json decode error: " .. json_str)
      return context.assistant_output
    end

    context.assistant_output = context.assistant_output .. data.response
    F.WriteContent(context.bufnr, context.winid, data.response)
    context.line = ""
  end
  return context.assistant_output
end

return workers_ai
