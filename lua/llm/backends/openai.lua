local LOG = require("llm.common.log")
local F = require("llm.common.api")
local job = require("plenary.job")
local backend_utils = require("llm.backends.utils")
local openai = {}

function openai.StreamingHandler(chunk, ctx)
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
        backend_utils.mark_reason_begin(ctx, false)
        ctx.reasoning_content = ctx.reasoning_content .. data.choices[1].delta.reasoning_content

        F.WriteContent(ctx.bufnr, ctx.winid, data.choices[1].delta.reasoning_content)
      elseif F.IsValid(data.choices[1].delta.content) then
        backend_utils.mark_reason_end(ctx, false)
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
  if type(chunk) == "string" then
    chunk = vim.fn.json_decode(chunk)
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

function openai.FunctionCalling(ctx, t)
  local msg = t.choices[1].message
  if not F.IsValid(msg.tool_calls) then
    return
  end
  local N = vim.tbl_count(msg.tool_calls)

  for i = 1, N do
    local name = msg.tool_calls[i]["function"].name
    local id = msg.tool_calls[i].id

    -- openai: arguments is string
    -- format_json_str: Tool_calls arguments may contain excessive quotation marks, causing JSON parsing to fail.
    local params = backend_utils.format_json_str(msg.tool_calls[i]["function"].arguments)
    local keys = vim.tbl_filter(function(item)
      return item["function"].name == name
    end, ctx.body.tools)[1]["function"].parameters.required

    local p = {}

    for _, k in pairs(keys) do
      table.insert(p, backend_utils.decode_escaped_string(params[k]))
    end

    if ctx.functions_tbl[name] == nil then
      LOG:ERROR(string.format("please configure %s in `functions_tbl`", name))
      return
    end

    local res = ctx.functions_tbl[name](unpack(p))
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
          openai.ParseHandler(c, ctx)
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

function openai.AppendToolsRespond(results, msg)
  local fc_type = "function"
  for _, fc_respond_str in pairs(results) do
    local status, fc_respond = pcall(vim.json.decode, fc_respond_str:sub(7))
    if status then
      if
        F.IsValid(fc_respond.choices)
        and F.IsValid(fc_respond.choices[1].delta)
        and F.IsValid(fc_respond.choices[1].delta.tool_calls)
      then
        -- LOG:INFO(fc_respond.choices[1].delta.tool_calls[1])
        if F.IsValid(fc_respond.choices[1].delta.tool_calls[1].id) then
          table.insert(msg, fc_respond.choices[1].delta.tool_calls[1])
          fc_type = fc_respond.choices[1].delta.tool_calls[1].type
        else
          msg[#msg][fc_type].arguments = msg[#msg][fc_type].arguments
            .. fc_respond.choices[1].delta.tool_calls[1][fc_type].arguments
        end
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
