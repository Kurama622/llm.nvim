local LOG = require("llm.common.log")
local F = require("llm.common.api")
local backend_utils = require("llm.backends.utils")
local json = vim.json
local lmstudio = {}

function lmstudio.StreamingHandler(chunk, ctx)
  if chunk == "data: [DONE]" or not chunk then
    return ctx.assistant_output
  end

  -- Gemini
  if chunk:sub(1, 6) == "Tokens" then
    return ctx.assistant_output
  end

  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    ctx.line = F.TrimLeadingWhitespace(ctx.line)
    local start_idx = ctx.line:find("data: ")
    local end_idx = ctx.line:find("}$")
    local json_str = nil
    if start_idx == nil or end_idx == nil then
      LOG:ERROR(ctx.line)
    end

    while start_idx ~= nil and end_idx ~= nil do
      if start_idx < end_idx then
        json_str = ctx.line:sub(start_idx + 6, end_idx)
      end

      local status, data = pcall(json.decode, json_str)

      if data.choices == nil or data.choices[1] == nil then
        ctx.line = ""
        break
      end

      if not status or not data.choices[1].delta.content then
        LOG:TRACE("json decode error:", json_str)
        break
      end

      -- add reasoning_content
      if F.IsValid(data.choices[1].delta.reasoning_content) then
        backend_utils.mark_reason_begin(ctx, false)
        ctx.reasoning_content = ctx.reasoning_content .. data.choices[1].delta.reasoning_content

        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.reasoning_content)
      elseif F.IsValid(data.choices[1].delta.content) then
        backend_utils.mark_reason_end(ctx, false)
        ctx.assistant_output = ctx.assistant_output .. data.choices[1].delta.content
        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.content)
      end

      if end_idx + 1 > #ctx.line then
        ctx.line = ""
        break
      else
        ctx.line = ctx.line:sub(end_idx + 1)
      end
      start_idx = ctx.line:find("data: ")
      end_idx = ctx.line:find("}$")
      if start_idx == nil or end_idx == nil then
        ctx.line = ""
      end
    end
  end
  return ctx.assistant_output
end

function lmstudio.ParseHandler(chunk, ctx)
  if type(chunk) == "string" then
    chunk = json.decode(chunk)
  end
  local success, err = pcall(function()
    if chunk and chunk.choices and chunk.choices[1] then
      ctx.assistant_output = chunk.choices[1].message.content
    else
      LOG:ERROR(chunk)
    end
  end)

  if success then
    return ctx.assistant_output
  else
    LOG:TRACE(chunk)
    LOG:ERROR("Error occurred:", err)
    return ""
  end
end

return lmstudio
