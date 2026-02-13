local LOG = require("llm.common.log")
local F = require("llm.common.api")
local job = require("plenary.job")
local backend_utils = require("llm.backends.utils")
local schedule_wrap, json = vim.schedule_wrap, vim.json
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
    local lstart, rstart = ctx.line:find("^data:%s*")
    local lend = ctx.line:find("}$")
    local json_str = nil
    if lstart == nil or lend == nil then
      LOG:ERROR(ctx.line)
    end

    while lstart ~= nil and lend ~= nil do
      if lstart < lend then
        json_str = ctx.line:sub(rstart + 1, lend)
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

      if lend + 1 > #ctx.line then
        ctx.line = ""
        break
      else
        ctx.line = ctx.line:sub(lend + 1)
      end
      lstart = ctx.line:find("^data:%s*")
      lend = ctx.line:find("}$")
      if lstart == nil or lend == nil then
        ctx.line = ""
      end
    end
  end
  return ctx.assistant_output
end

function openai.ParseHandler(chunk, ctx)
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
  -- update curl request body file
  require("llm.common.file_io").SaveFile(ctx.request_body_file, json.encode(ctx.body))

  job
    :new({
      command = "curl",
      args = ctx.args,
      on_stdout = schedule_wrap(function(_, c)
        if ctx.stream then
          ctx.assistant_output = openai.StreamingHandler(c, ctx)
        else
          openai.ParseHandler(c, ctx)
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

function openai.AppendToolsRespond(results, msg)
  local fc_type = "function"
  for _, fc_respond_str in pairs(results) do
    local lstart, rstart = fc_respond_str:find("^data:%s*")
    if lstart == nil then
      rstart = 6
    end

    local status, fc_respond = pcall(vim.json.decode, fc_respond_str:sub(rstart + 1))
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

function openai.StreamingTblHandler(results)
  local assistant_output, line = "", ""
  for _, chunk in pairs(results) do
    if chunk == "data: [DONE]" or not chunk then
      return assistant_output
    end

    -- Gemini
    if chunk:sub(1, 6) == "Tokens" then
      return assistant_output
    end

    local tail = chunk:sub(-1, -1)
    if tail:sub(1, 1) ~= "}" then
      line = line .. chunk
    else
      line = line .. chunk
      line = F.TrimLeadingWhitespace(line)
      local lstart, rstart = line:find("^data:%s*")
      local lend = line:find("}$")
      local json_str = nil
      if lstart == nil or lend == nil then
        LOG:ERROR(line)
      end

      while lstart ~= nil and lend ~= nil do
        if lstart < lend then
          json_str = line:sub(rstart + 1, lend)
        end

        local status, data = pcall(json.decode, json_str)

        if data.choices == nil or data.choices[1] == nil then
          line = ""
          break
        end

        if not status or not data.choices[1].delta.content then
          LOG:TRACE("json decode error:", json_str)
          break
        end
        if F.IsValid(data.choices[1].delta.content) then
          assistant_output = assistant_output .. data.choices[1].delta.content
        end

        if lend + 1 > #line then
          line = ""
          break
        else
          line = line:sub(lend + 1)
        end
        lstart = line:find("^data:%s*")
        lend = line:find("}$")
        if lstart == nil or lend == nil then
          line = ""
        end
      end
    end
  end
end
return openai
