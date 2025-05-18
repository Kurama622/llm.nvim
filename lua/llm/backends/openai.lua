local LOG = require("llm.common.log")
local F = require("llm.common.api")
local job = require("plenary.job")
local io_utils = require("llm.common.io.utils")
local backend_utils = require("llm.backends.utils")
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
    ctx.line = F.TrimLeadingWhitespace(ctx.line)
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
        LOG:TRACE("json decode error:", json_str)
        break
      end

      -- add reasoning_content
      if F.IsValid(data.choices[1].delta.reasoning_content) then
        backend_utils.mark_reason_begin(ctx)
        ctx.reasoning_content = ctx.reasoning_content .. data.choices[1].delta.reasoning_content

        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.reasoning_content)
      elseif F.IsValid(data.choices[1].delta.content) then
        backend_utils.mark_reason_end(ctx)
        ctx.assistant_output = ctx.assistant_output .. data.choices[1].delta.content
        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.content)
      end

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

function openai.FunctionCalling(ctx, chunk, messages)
  local msg = vim.json.decode(chunk).choices[1].message
  if not F.IsValid(msg.tool_calls) then
    return
  end
  local N = vim.tbl_count(msg.tool_calls)

  for i = 1, N do
    local name = msg.tool_calls[i]["function"].name
    local id = msg.tool_calls[i].id

    local params = vim.json.decode(msg.tool_calls[i]["function"].arguments)
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
          ctx.assistant_output = openai.StreamingHandler(c, ctx)
        else
          openai.ParseHandler(vim.fn.json_decode(c), ctx)
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

function openai.AppendToolsRespond(chunk, msg)
  if chunk == "data: [DONE]" then
    return
  end
  if F.IsValid(chunk) then
    local tool_calls = vim.json.decode(chunk:sub(7)).choices[1].delta.tool_calls
    if F.IsValid(tool_calls) then
      if F.IsValid(tool_calls[1].id) then
        table.insert(msg, { id = tool_calls[1].id, type = "function", ["function"] = { name = "", arguments = "" } })
      end
      if F.IsValid(tool_calls[1]["function"].name) then
        msg[#msg]["function"].name = msg[#msg]["function"].name .. tool_calls[1]["function"].name
      end
      if F.IsValid(tool_calls[1]["function"].arguments) then
        msg[#msg]["function"].arguments = msg[#msg]["function"].arguments .. tool_calls[1]["function"].arguments
      end
    end
  end
end

function openai.GetToolsRespond(chunk, msg)
  if F.IsValid(chunk) then
    local tool_calls = vim.json.decode(chunk).choices[1].message.tool_calls
    if F.IsValid(tool_calls) then
      for _, item in ipairs(tool_calls) do
        table.insert(msg, item)
      end
    end
  end
end
return openai
