local LOG = require("llm.common.log")
local F = require("llm.common.api")
local ollama = {}

function ollama.StreamingHandler(chunk, context)
  if not chunk then
    return context.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    context.line = context.line .. chunk
  else
    context.line = context.line .. chunk
    local status, data = pcall(vim.fn.json_decode, context.line)
    if not status or not data.message.content then
      LOG:TRACE("json decode error: " .. data)
      return context.assistant_output
    end
    context.assistant_output = context.assistant_output .. data.message.content
    F.WriteContent(context.bufnr, context.winid, data.message.content)
    context.line = ""
  end
  return context.assistant_output
end

return ollama
