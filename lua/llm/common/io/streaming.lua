local M = {
  required_params = {},
}

local conf = require("llm.config")
local job = require("plenary.job")
local F = require("llm.common.api")
local backends = require("llm.backends")
local state = require("llm.state")
local LOG = require("llm.common.log")
local io_utils = require("llm.common.io.utils")
local fio = require("llm.common.file_io")
local schedule_wrap, json = vim.schedule_wrap, vim.json

local function exit_callback(opts, ctx)
  table.insert(opts.messages, io_utils.gen_messages(ctx))
  local newline_func = schedule_wrap(function()
    F.NewLine(opts.bufnr, opts.winid)
  end)
  newline_func()
  local name = opts._name or "chat"
  state.llm.worker.jobs[name] = nil
  if opts.exit_handler ~= nil then
    local callback_func = schedule_wrap(function()
      opts.exit_handler(ctx.assistant_output)
    end)
    callback_func()
  end
  if state.summarize_suggestions.ctx then
    setmetatable(state.summarize_suggestions, { __index = ctx })
  end

  io_utils.reset_io_status(opts)
  -- reset tool_calls content
  backends.msg_tool_calls_content = {}
end

function M.GetStreamingOutput(opts)
  local ui = require("llm.common.ui")
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")

  state.args_template = opts.args
  local required_params = M.required_params

  for _, key in pairs(state.model_params) do
    if key ~= "parse_handler" then
      required_params[key] = io_utils.get_params_value(key, opts)
    end
  end
  opts.diagnostic = opts.diagnostic or conf.configs.diagnostic
  opts.lsp = opts.lsp or conf.configs.lsp

  if required_params.fetch_key ~= nil then
    if type(required_params.fetch_key) == "function" then
      LLM_KEY = required_params.fetch_key()
    elseif type(required_params.fetch_key) == "string" then
      LLM_KEY = required_params.fetch_key
    else
      LOG:ERROR("fetch_key must be a string or function type")
    end
  end

  local authorization = "Authorization: Bearer " .. LLM_KEY

  if LLM_KEY == "NONE" then
    authorization = ""
  end

  -- set request body params
  local body = {
    stream = true,
    messages = opts.messages,
    tools = required_params.schema,
  }

  opts.api_type = required_params.api_type
  if required_params.api_type == "workers-ai" then
    required_params.url = string.format(required_params.url, ACCOUNT, required_params.model)
  elseif required_params.api_type == "ollama" then
    body.options = {}
  elseif required_params.api_type == "openai" then
    for _, msg in pairs(body.messages) do
      if msg.role == "user" and F.IsValid(msg.images) then
        local msg_content = msg.content
        msg.content = {}
        for i, image in pairs(msg.images) do
          local format = opts.format[i] or "jpeg"
          table.insert(msg.content, {
            ["type"] = "image_url",
            image_url = { url = "data:image/" .. format .. ";base64," .. image, detail = opts.detail },
          })
        end
        msg.images = nil
        table.insert(msg.content, { ["type"] = "text", text = msg_content })
      end
    end
  end

  local params = {
    max_tokens = required_params.max_tokens,
    keep_alive = required_params.keep_alive,
    temperature = required_params.temperature,
    top_p = required_params.top_p,
    enable_thinking = required_params.enable_thinking,
    thinking_budget = required_params.thinking_budget,
  }

  for param_name, param_value in pairs(params) do
    io_utils.add_request_body_params(body, param_name, param_value, required_params.api_type)
  end

  if required_params.api_type == "ollama" then
    if not F.IsValid(body.options) then
      body.options = nil
    end
  end

  local ctx = {
    line = "",
    assistant_output = "",
    reasoning_content = "",
    bufnr = opts.bufnr,
    winid = opts.winid,
    body = body,
    functions_tbl = required_params.functions_tbl,
    stream = true,
  }
  local stream_output =
    backends.get_streaming_handler(required_params.streaming_handler, required_params.api_type, conf.configs, ctx)

  state.llm.start_line = vim.api.nvim_buf_line_count(opts.bufnr)
  local _args = nil
  if required_params.url ~= nil then
    body.model = required_params.model

    local data_file = conf.configs.curl_data_cache_path .. "/streaming-data"
    fio.SaveFile(data_file, json.encode(body))
    if opts.args == nil then
      _args = {
        "-s",
        "-m",
        required_params.timeout,
        required_params.url,
        "-N",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        authorization,
        "-d",
        "@" .. data_file,
      }
    else
      local env = {
        url = required_params.url,
        authorization = authorization,
        body = body,
      }

      setmetatable(env, { __index = _G })
      _args = F.GetUserRequestArgs(opts.args, env)
    end

    if stream_output == nil then
      -- if url is set, but not set streaming_handler, stream_output will be `zhipu` by default
      stream_output = function(chunk)
        if not chunk then
          return
        end
        local tail = chunk:sub(-1, -1)
        if tail:sub(1, 1) ~= "}" then
          ctx.line = ctx.line .. chunk
        else
          ctx.line = ctx.line .. chunk

          local start_idx = ctx.line:find("data: ", 1, true)
          local end_idx = ctx.line:find("}}]}", 1, true)
          local json_str = nil

          while start_idx ~= nil and end_idx ~= nil do
            if start_idx < end_idx then
              json_str = ctx.line:sub(7, end_idx + 3)
            end
            local data = json.decode(json_str)
            ctx.assistant_output = ctx.assistant_output .. data.choices[1].delta.content
            F.WriteContent(opts.bufnr, opts.winid, data.choices[1].delta.content)

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
    end
  end
  ctx.args = F.tbl_slice(_args, 1, -2)

  opts.body = body
  opts.args = _args
  local request_job = job:new({
    command = "curl",
    args = _args,
    on_stdout = schedule_wrap(function(_, chunk)
      ui.clear_spinner_extmark(opts)
      if required_params.api_type or required_params.streaming_handler then
        ctx.assistant_output = stream_output(chunk)
      else
        stream_output(chunk)
      end
      -- TODO: Add stdout handling
    end),
    on_stderr = schedule_wrap(function(_, err)
      if err ~= nil then
        LOG:ERROR(err)
      end
      -- TODO: Add error handling
    end),
    on_exit = schedule_wrap(function(request_job)
      if ctx.body.tools ~= nil then
        backends.get_tools_respond(required_params.api_type, conf.configs, ctx)(request_job:result())
        ctx.callback = function()
          exit_callback(opts, ctx)
        end
        backends.get_function_calling(required_params.api_type, conf.configs, ctx)(
          backends.gen_msg_with_tool_calls(required_params.api_type, conf.configs, ctx)
        )
      else
        exit_callback(opts, ctx)
      end
    end),
  })

  ui.display_spinner_extmark(opts)
  if F.IsValid(state.quote_buffers) then
    table.insert(opts.body.messages, {
      role = "user",
      content = "This is the content of the buffer involved:",
      type = "quote_buffers",
    })
    for idx, buffer in ipairs(state.quote_buffers) do
      opts.enable_buffer_idx = idx
      buffer:callback(opts, request_job)
    end
  elseif F.IsValid(state.enabled_cmds) then
    for idx, cmd in ipairs(state.enabled_cmds) do
      opts.enable_cmds_idx = idx
      cmd.callback(conf.configs.web_search, opts.messages, opts, request_job)
    end
  else
    local name = opts._name or "chat"
    request_job:start()
    state.llm.worker.jobs[name] = request_job
  end
end

return M
