local LOG = require("llm.common.log")
local F = require("llm.common.api")
local openai = {}

function openai.StreamingHandler(chunk, ctx)
  if chunk == "data: [DONE]" or not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    ctx.line = F.trim_leading_whitespace(ctx.line)
    local start_idx = ctx.line:find("data: ", 1, true)
    local end_idx = ctx.line:find("}]", 1, true)
    local json_str = nil

    while start_idx ~= nil and end_idx ~= nil do
      if start_idx < end_idx then
        json_str = ctx.line:sub(7, end_idx + 1) .. "}"
      end

      local status, data = pcall(vim.fn.json_decode, json_str)

      if data.choices == nil or data.choices[1] == nil then
        ctx.line = ""
        break
      end

      if not status or not data.choices[1].delta.content then
        LOG:TRACE("json decode error: " .. json_str)
        break
      end

      ctx.assistant_output = ctx.assistant_output .. data.choices[1].delta.content
      F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.content)

      if end_idx + 2 > #ctx.line then
        ctx.line = ""
        break
      else
        ctx.line = ctx.line:sub(end_idx + 2)
      end
      start_idx = ctx.line:find("data: ", 1, true)
      end_idx = ctx.line:find("}]", 1, true)
      if start_idx == nil or end_idx == nil then
        ctx.line = ""
      end
    end
  end
  return ctx.assistant_output
end

function openai.ParseHandler(chunk, ctx)
  local success, err = pcall(function()
    if chunk and chunk.choices and chunk.choices[1] then
      ctx.assistant_output = chunk.choices[1].message.content
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
return openai
