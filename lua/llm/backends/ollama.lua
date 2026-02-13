local LOG = require("llm.common.log")
local F = require("llm.common.api")
local backend_utils = require("llm.backends.utils")
local schedule_wrap, json = vim.schedule_wrap, vim.json
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
    local status, data = pcall(json.decode, ctx.line)
    if not status or not data.message.content then
      LOG:TRACE("json decode error:", data)
      return ctx.assistant_output
    end

    -- add reasoning_content
    if F.IsValid(data.message.thinking) then
      backend_utils.mark_reason_begin(ctx, true)
      ctx.reasoning_content = ctx.reasoning_content .. data.message.thinking

      F.WriteContent(ctx.bufnr, ctx.winid, data.message.thinking)
    else
      backend_utils.mark_reason_end(ctx, true)
      ctx.assistant_output = ctx.assistant_output .. data.message.content
      F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    end
    ctx.line = ""
  end
  return ctx.assistant_output
end

function ollama.ParseHandler(chunk, ctx)
  if type(chunk) == "string" then
    chunk = json.decode(chunk)
  end
  local success, err = pcall(function()
    if chunk and chunk.message then
      ctx.assistant_output = chunk.message.content
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

function ollama.FunctionCalling(ctx, t)
  local msg = t.message
  if not F.IsValid(msg.tool_calls) then
    return
  end
  local N = vim.tbl_count(msg.tool_calls)

  for i = 1, N do
    local name = msg.tool_calls[i]["function"].name
    local id = msg.tool_calls[i].id

    -- ollama: arguments is table
    local params = msg.tool_calls[i]["function"].arguments
    local keys = vim.tbl_filter(function(item)
      return item["function"].name == name
    end, ctx.body.tools)[1]["function"].parameters.required

    local p = {}

    for _, k in pairs(keys) do
      table.insert(p, params[k])
    end

    if ctx.functions_tbl[name] == nil then
      LOG:ERROR(string.format("please configure %s in `functions_tbl`", name))
      return
    end
    local res = ctx.functions_tbl[name](unpack(p))
    table.insert(ctx.body.messages, msg)
    table.insert(ctx.body.messages, { role = "tool", content = tostring(res), tool_call_id = id })
  end
  -- update curl request body file
  require("llm.common.file_io").SaveFile(ctx.request_body_file, json.encode(ctx.body))

  require("plenary.job")
    :new({
      command = "curl",
      args = ctx.args,
      on_stdout = schedule_wrap(function(_, c)
        if ctx.stream then
          ctx.assistant_output = ollama.StreamingHandler(c, ctx)
        else
          ctx.assistant_output = ollama.ParseHandler(c, ctx)
        end
      end),
      on_exit = schedule_wrap(function()
        if ctx.callback then
          ctx.callback()
        end
      end),
    })
    :start()
end

function ollama.AppendToolsRespond(chunk, msg)
  if F.IsValid(chunk) then
    for _, fc_respond_str in pairs(chunk) do
      local status, fc_respond = pcall(vim.json.decode, fc_respond_str)

      if status then
        local tool_calls = fc_respond.message.tool_calls
        if F.IsValid(tool_calls) then
          if F.IsValid(tool_calls[1]["function"].name) then
            table.insert(msg, {
              ["function"] = {
                name = tool_calls[1]["function"].name,
                arguments = tool_calls[1]["function"].arguments,
              },
            })
          end
        end
      end
    end
  end
end

function ollama.GetToolsRespond(chunk, msg)
  if F.IsValid(chunk) then
    local tool_calls = json.decode(chunk).message.tool_calls
    if F.IsValid(tool_calls) then
      for _, item in ipairs(tool_calls) do
        table.insert(msg, item)
      end
    end
  end
end

function ollama.StreamingTblHandler(results)
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
      local status, data = pcall(json.decode, line)
      if not status or not data.message.content then
        LOG:TRACE("json decode error:", data)
        return assistant_output
      elseif data.done then
        return assistant_output
      end

      assistant_output = assistant_output .. data.message.content
      line = ""
    end
  end
end
return ollama
