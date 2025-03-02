local LOG = require("llm.common.log")
local F = require("llm.common.api")
local workers_ai = {}

function workers_ai.StreamingHandler(chunk, ctx)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    local json_str = ctx.line:sub(7, -1)
    local status, data = pcall(vim.fn.json_decode, json_str)

    if not status then
      LOG:TRACE("json decode error: " .. json_str)
      return ctx.assistant_output
    end

    ctx.assistant_output = ctx.assistant_output .. data.response
    F.WriteContent(ctx.bufnr, ctx.winid, data.response)
    ctx.line = ""
  end
  return ctx.assistant_output
end

function workers_ai.ParseHandler(chunk, ctx)
  local success, err = pcall(function()
    if chunk and chunk.result then
      ctx.assistant_output = chunk.result.response
    else
      error(vim.inspect(chunk))
    end
  end)

  if success then
    return ctx.assistant_output
  else
    LOG:TRACE(vim.inspect(chunk))
    LOG:ERROR("Error occurred:" .. err)
    return ""
  end
end

return workers_ai
