local LOG = require("llm.common.log")
local F = require("llm.common.api")
local glm = {}

function glm.StreamingHandler(chunk, ctx)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk

    local start_idx = ctx.line:find("data: ", 1, true)
    local end_idx = ctx.line:find("}}]}", 1, true)
    local json_str = nil

    if start_idx == nil or end_idx == nil then
      LOG:TRACE(ctx.line)
    else
      while start_idx ~= nil and end_idx ~= nil do
        if start_idx < end_idx then
          json_str = ctx.line:sub(7, end_idx + 3)
        end

        local status, data = pcall(vim.fn.json_decode, json_str)

        if not status or not data.choices[1].delta.content then
          LOG:TRACE("json decode error:", json_str)
          break
        end

        ctx.assistant_output = ctx.assistant_output .. data.choices[1].delta.content
        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.content)

        if end_idx + 4 > #ctx.line then
          ctx.line = ""
          break
        else
          ctx.line = ctx.line:sub(end_idx + 4)
        end
        start_idx = ctx.line:find("data: ", 1, true)
        end_idx = ctx.line:find("}}]}", 1, true)
      end
    end
  end
  return ctx.assistant_output
end

function glm.ParseHandler(chunk, ctx)
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

function glm.StreamingTblHandler(results)
  local assistant_output, line = "", ""
  for _, chunk in pairs(results) do
    if not chunk then
      return assistant_output
    end
    local tail = chunk:sub(-1, -1)
    if tail:sub(1, 1) ~= "}" then
      line = line .. chunk
    else
      line = line .. chunk

      local start_idx = line:find("data: ", 1, true)
      local end_idx = line:find("}}]}", 1, true)
      local json_str = nil

      if start_idx == nil or end_idx == nil then
        LOG:TRACE(line)
      else
        while start_idx ~= nil and end_idx ~= nil do
          if start_idx < end_idx then
            json_str = line:sub(7, end_idx + 3)
          end

          local status, data = pcall(vim.fn.json_decode, json_str)

          if not status or not data.choices[1].delta.content then
            LOG:TRACE("json decode error:", json_str)
            break
          end

          assistant_output = assistant_output .. data.choices[1].delta.content

          if end_idx + 4 > #line then
            line = ""
            break
          else
            line = line:sub(end_idx + 4)
          end
          start_idx = line:find("data: ", 1, true)
          end_idx = line:find("}}]}", 1, true)
        end
      end
    end
  end
end
return glm
