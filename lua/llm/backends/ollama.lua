local LOG = require("llm.common.log")
local job = require("plenary.job")
local F = require("llm.common.api")
local io_utils = require("llm.common.io.utils")
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
      LOG:TRACE("json decode error:", data)
      return ctx.assistant_output
    end
    ctx.assistant_output = ctx.assistant_output .. data.message.content
    F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    ctx.line = ""
  end
  return ctx.assistant_output
end

function ollama.ParseHandler(chunk, ctx)
  if type(chunk) == "string" then
    chunk = vim.fn.json_decode(chunk)
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

function ollama.FunctionCalling(ctx, chunk)
  local msg = vim.json.decode(chunk).message
  local N = vim.tbl_count(msg.tool_calls)

  for i = 1, N do
    local name = msg.tool_calls[i]["function"].name
    local id = msg.tool_calls[i].id

    local params = msg.tool_calls[i]["function"].arguments
    local keys = vim.tbl_filter(function(item)
      return item["function"].name == name
    end, ctx.body.tools)[1]["function"].parameters.required

    local p = {}

    for _, k in pairs(keys) do
      table.insert(p, params[k])
    end
    local fstring = string.dump(ctx.functions_tbl[name])
    local tool_func = load(fstring)

    if tool_func == nil then
      LOG:ERROR("please configure your `functions_tbl`")
      return
    end
    local res = tool_func(unpack(p))
    table.insert(ctx.body.messages, msg)
    table.insert(ctx.body.messages, { role = "tool", content = tostring(res), tool_call_id = id })
  end
  table.insert(ctx.args, vim.fn.json_encode(ctx.body))

  job
    :new({
      command = "curl",
      args = ctx.args,
      on_stdout = vim.schedule_wrap(function(_, c)
        if ctx.stream then
          ctx.assistant_output = ollama.StreamingHandler(c, ctx)
        else
          ctx.assistant_output = ollama.ParseHandler(c, ctx)
        end
      end),
      on_exit = vim.schedule_wrap(function()
        if ctx.callback then
          ctx.callback()
        end
      end),
    })
    :start()
end

function ollama.AppendToolsRespond(chunk, msg)
  if F.IsValid(chunk) then
    local tool_calls = vim.json.decode(chunk).message.tool_calls
    if F.IsValid(tool_calls) then
      if F.IsValid(tool_calls[1]["function"].name) then
        table.insert(
          msg,
          { ["function"] = { name = tool_calls[1]["function"].name, arguments = tool_calls[1]["function"].arguments } }
        )
      end
    end
  end
end

function ollama.GetToolsRespond(chunk, msg)
  if F.IsValid(chunk) then
    local tool_calls = vim.json.decode(chunk).message.tool_calls
    if F.IsValid(tool_calls) then
      for _, item in ipairs(tool_calls) do
        table.insert(msg, item)
      end
    end
  end
end
return ollama
