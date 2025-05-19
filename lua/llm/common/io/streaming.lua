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

local function exit_callback(opts, ctx, worker)
  table.insert(opts.messages, io_utils.gen_messages(ctx))
  local newline_func = vim.schedule_wrap(function()
    F.NewLine(opts.bufnr, opts.winid)
  end)
  newline_func()
  worker.job = nil
  if opts.exit_handler ~= nil then
    local callback_func = vim.schedule_wrap(function()
      opts.exit_handler(ctx.assistant_output)
    end)
    callback_func()
  end
  if state.summarize_suggestions.ctx then
    setmetatable(state.summarize_suggestions, { __index = ctx })
  end

  io_utils.reset_io_status()
  -- reset tool_calls content
  backends.msg_tool_calls_content = {}
end

function M.GetStreamingOutput(opts)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")
  local required_params = M.required_params

  for _, key in pairs(state.model_params) do
    if key ~= "parse_handler" then
      required_params[key] = io_utils.get_params_value(key, opts)
    end
  end

  if required_params.api_type == "workers-ai" then
    required_params.url = string.format(required_params.url, ACCOUNT, required_params.model)
  end

  if required_params.fetch_key ~= nil then
    LLM_KEY = required_params.fetch_key()
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

  local params = {
    max_tokens = required_params.max_tokens,
    keep_alive = required_params.keep_alive,
    temperatrue = required_params.temperatrue,
    top_p = required_params.top_p,
    enable_thinking = required_params.enable_thinking,
    thinking_budget = required_params.thinking_budget,
  }

  for param_name, param_value in pairs(params) do
    io_utils.add_request_body_params(body, param_name, param_value)
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

  local _args = nil
  if required_params.url ~= nil then
    body.model = required_params.model

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
        vim.fn.json_encode(body),
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
            local data = vim.fn.json_decode(json_str)
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
  else
    if opts.args == nil then
      LOG:WARN(
        "[Deprecated Usage] Please configure the url (Note: For cloudflare, you should use https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s"
      )
      _args = {
        "-s",
        "-m",
        required_params.timeout,
        string.format("https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s", ACCOUNT, required_params.model),
        "-N",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        authorization,
        "-d",
        vim.fn.json_encode(body),
      }
    else
      local env = {
        ACCOUNT = ACCOUNT,
        model = required_params.model,
        authorization = authorization,
        body = body,
      }

      setmetatable(env, { __index = _G })
      _args = F.GetUserRequestArgs(opts.args, env)
    end

    if stream_output == nil then
      -- if url is not set, stream_output will be `workers-ai` by default
      stream_output = function(chunk)
        if not chunk then
          return
        end
        local tail = chunk:sub(-1, -1)
        if tail:sub(1, 1) ~= "}" then
          ctx.line = ctx.line .. chunk
        else
          ctx.line = ctx.line .. chunk
          local json_str = ctx.line:sub(7, -1)
          local data = vim.fn.json_decode(json_str)
          ctx.assistant_output = ctx.assistant_output .. data.response
          F.WriteContent(opts.bufnr, opts.winid, data.response)
          ctx.line = ""
        end
      end
    end
  end
  ctx.args = F.tbl_slice(_args, 1, -2)

  local worker = { job = nil }
  worker.job = job:new({
    command = "curl",
    args = _args,
    on_stdout = vim.schedule_wrap(function(_, chunk)
      if required_params.api_type or required_params.streaming_handler then
        ctx.assistant_output = stream_output(chunk)
      else
        stream_output(chunk)
      end
      if ctx.body.tools ~= nil then
        backends.get_tools_respond(required_params.api_type, conf.configs, ctx)(chunk)
      end
      -- TODO: Add stdout handling
    end),
    on_stderr = function(_, err)
      if err ~= nil then
        LOG:ERROR(err)
      end
      -- TODO: Add error handling
    end,
    on_exit = vim.schedule_wrap(function()
      if ctx.body.tools ~= nil and F.IsValid(backends.msg_tool_calls_content) then
        ctx.callback = function()
          exit_callback(opts, ctx, worker)
        end
        backends.get_function_calling(required_params.api_type, conf.configs, ctx)(
          vim.fn.json_encode(backends.gen_msg_with_tool_calls(required_params.api_type, conf.configs, ctx))
        )
      else
        exit_callback(opts, ctx, worker)
      end
    end),
  })
  worker.job:start()

  return worker
end

return M
