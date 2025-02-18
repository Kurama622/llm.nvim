local LOG = require("llm.common.log")
local F = require("llm.common.api")
local glm = {}

function glm.StreamingHandler(chunk, context)
  if not chunk then
    return context.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    context.line = context.line .. chunk
  else
    context.line = context.line .. chunk

    local start_idx = context.line:find("data: ", 1, true)
    local end_idx = context.line:find("}}]}", 1, true)
    local json_str = nil

    if start_idx == nil or end_idx == nil then
      LOG:TRACE(context.line)
    else
      while start_idx ~= nil and end_idx ~= nil do
        if start_idx < end_idx then
          json_str = context.line:sub(7, end_idx + 3)
        end

        local status, data = pcall(vim.fn.json_decode, json_str)

        if not status or not data.choices[1].delta.content then
          LOG:TRACE("json decode error: " .. json_str)
          break
        end

        context.assistant_output = context.assistant_output .. data.choices[1].delta.content
        F.WriteContent(context.bufnr, context.winid, data.choices[1].delta.content)

        if end_idx + 4 > #context.line then
          context.line = ""
          break
        else
          context.line = context.line:sub(end_idx + 4)
        end
        start_idx = context.line:find("data: ", 1, true)
        end_idx = context.line:find("}}]}", 1, true)
      end
    end
  end
  return context.assistant_output
end

return glm
