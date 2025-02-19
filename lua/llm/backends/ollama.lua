local LOG = require("llm.common.log")
local F = require("llm.common.api")
local ollama = {}

function ollama.StreamingHandler(chunk, ctx)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    local status, data = pcall(vim.fn.json_decode, ctx.line)
    if not status or not data.message.content then
      LOG:TRACE("json decode error: " .. data)
      return ctx.assistant_output
    end
    ctx.assistant_output = ctx.assistant_output .. data.message.content
    F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    ctx.line = ""
  end
  return ctx.assistant_output
end

function ollama.ParseHandler(chunk, ctx)
  local success, err = pcall(function()
    ctx.assistant_output = chunk.message.content
  end)

  if success then
    return ctx.assistant_output
  else
    LOG:TRACE(vim.inspect(chunk))
    LOG:ERROR("Error occurred:" .. err)
    return ""
  end
end
return ollama
