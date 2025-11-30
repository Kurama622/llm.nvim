local Popup = require("nui.popup")
local conf = require("llm.config")
local api = require("llm.common.api")
local backends = require("llm.backends")
local job = require("plenary.job")
local LOG = require("llm.common.log")
local state = require("llm.state")
local io_utils = require("llm.common.io.utils")
local F = require("llm.common.api")
local fio = require("llm.common.file_io")
local schedule_wrap, json = vim.schedule_wrap, vim.json

local io_parse = {
  required_params = {},
}
local function exit_callback(opts, ctx, waiting_state)
  table.insert(opts.messages, { role = "assistant", content = ctx.assistant_output })
  waiting_state.box:unmount()
  waiting_state.timer:stop()
  if opts.exit_handler ~= nil then
    local callback_func = schedule_wrap(function()
      opts.exit_handler(ctx.assistant_output)
    end)
    callback_func()
  end
  -- reset tool_calls content
  backends.msg_tool_calls_content = {}
end

function io_parse.GetOutput(opts)
  local ui = require("llm.common.ui")
  local wait_box_opts = ui.wait_ui_opts()
  local wait_box = Popup(wait_box_opts)

  local waiting_state = {
    box = wait_box,
    box_opts = wait_box_opts,
    bufnr = wait_box.bufnr,
    winid = wait_box.winid,
  }

  waiting_state.box:mount()
  ui.show_spinner(waiting_state)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")
  local required_params = io_parse.required_params

  for _, key in pairs(state.model_params) do
    if key ~= "streaming_handler" then
      required_params[key] = io_utils.get_params_value(key, opts)
    end
  end

  if required_params.api_type == "workers-ai" then
    required_params.url = string.format(required_params.url, ACCOUNT, required_params.model)
  end

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

  local body = {
    stream = false,
    messages = opts.messages,
    tools = required_params.schema,
  }

  if required_params.api_type == "ollama" then
    body.options = {}
  end

  local params = {
    max_tokens = required_params.max_tokens,
    keep_alive = required_params.keep_alive,
    temperature = required_params.temperature,
    top_p = required_params.top_p,
    enable_thinking = required_params.enable_thinking,
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
    assistant_output = "",
    body = body,
    functions_tbl = required_params.functions_tbl,
    stream = false,
  }

  local parse = backends.get_parse_handler(required_params.parse_handler, required_params.api_type, conf.configs, ctx)
  local _args = nil
  if required_params.url ~= nil then
    body.model = required_params.model
    local data_file = conf.configs.curl_data_cache_path .. "/non-streaming-data"
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
        LLM_KEY = LLM_KEY,
        body = body,
        authorization = authorization,
      }

      setmetatable(env, { __index = _G })
      _args = api.GetUserRequestArgs(opts.args, env)
    end

    if parse == nil then
      -- if url is set, but not set parse_handler, parse will be `zhipu` by default
      parse = function(chunk)
        ctx.assistant_output = chunk.choices[1].message.content
        return ctx.assistant_output
      end
    end
  end
  ctx.args = F.tbl_slice(_args, 1, -2)

  local request_job = job:new({
    command = "curl",
    args = _args,
    on_stdout = schedule_wrap(function(_, data)
      local str = api.TrimLeadingWhitespace(data)
      local prefix = str:sub(1, 1)
      if prefix ~= "{" then
        if prefix ~= "" then
          LOG:ERROR(data)
        end
        return
      end
      local success, result = pcall(json.decode, str)
      if success then
        ctx.assistant_output = parse(result)
      else
        LOG:ERROR("Error occurred:", result)
      end
      if ctx.body.tools ~= nil then
        backends.get_tools_respond(required_params.api_type, conf.configs, ctx)(data)
      end
    end),
    on_stderr = schedule_wrap(function(_, err)
      if err ~= nil then
        LOG:ERROR(err)
      end
      -- TODO: Add error handling
    end),
    on_exit = schedule_wrap(function()
      if ctx.body.tools ~= nil and F.IsValid(backends.msg_tool_calls_content) then
        ctx.callback = function()
          exit_callback(opts, ctx, waiting_state)
        end
        backends.get_function_calling(required_params.api_type, conf.configs, ctx)(
          backends.gen_msg_with_tool_calls(required_params.api_type, conf.configs, ctx)
        )
      else
        exit_callback(opts, ctx, waiting_state)
      end
    end),
  })
  local succ, err = pcall(function()
    request_job:start()
  end)

  if not succ then
    if waiting_state.box then
      waiting_state.timer:stop()
      waiting_state.box:unmount()
    end
    LOG:ERROR(err)
  end
end
return io_parse
