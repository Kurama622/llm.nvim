local conf = require("llm.config")
local backends = require("llm.backends")
local LOG = require("llm.common.log")
local state = require("llm.state")
local io_utils = require("llm.common.io.utils")
local F = require("llm.common.api")
local schedule_wrap, json = vim.schedule_wrap, vim.json

local io_parse = {
  required_params = {},
}
local function exit_callback(opts, ctx, waiting_state)
  table.insert(opts.messages, { role = "assistant", content = ctx.assistant_output })
  while waiting_state.timer:is_active() do
    waiting_state.box:unmount()
    waiting_state.timer:close()
    waiting_state.box = nil
  end
  if opts.exit_handler ~= nil then
    local callback_func = schedule_wrap(function()
      opts.exit_handler(ctx.assistant_output)
    end)
    callback_func()
  end
  -- reset tool_calls content
  backends.msg_tool_calls_content = {}
end
local function validate_str_and_log_error(str)
  -- Display errors returned by the request:
  -- request exceeds rate limit, incorrect api_key, etc.
  local prefix = str:sub(1, 1)
  if prefix ~= "{" then
    if prefix ~= "" then
      LOG:ERROR(str)
    else
      LOG:ERROR("The model returned an empty response.")
    end
    return false
  end
  return true
end

function io_parse.GetOutput(opts)
  return coroutine.wrap(function()
    local co = assert(coroutine.running())
    local ui = require("llm.common.ui")
    local wait_box_opts = ui.wait_ui_opts()
    local wait_box = require("nui.popup")(wait_box_opts)

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

    local body = {
      stream = false,
      messages = opts.messages,
      tools = required_params.schema,
    }

    if required_params.api_type == "ollama" then
      body.options = {}
    elseif required_params.api_type == "copilot" then
      require("llm.backends.copilot"):get_authorization_token(LLM_KEY, co)
      LLM_KEY = coroutine.yield()
    end

    local authorization = "Authorization: Bearer " .. LLM_KEY
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
      line = "",
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
      ctx.request_body_file = data_file
      require("llm.common.file_io").SaveFile(data_file, json.encode(body))

      if opts.args == nil then
        _args = { "-s", "-m", required_params.timeout }

        -- set curl proxy
        if required_params.proxy then
          if required_params.proxy == "noproxy" then
            table.insert(_args, "--noproxy")
            table.insert(_args, "*")
          else
            table.insert(_args, "-x")
            table.insert(_args, required_params.proxy)
          end
        end

        if required_params.api_type == "copilot" then
          local nvim_version = vim.version()
          table.insert(_args, "-H")
          table.insert(_args, "Copilot-Integration-Id: vscode-chat")
          table.insert(_args, "-H")
          table.insert(
            _args,
            ("Editor-Version: Neovim/%d.%d.%d"):format(nvim_version.major, nvim_version.minor, nvim_version.patch)
          )
        end

        for _, arg in ipairs({
          "-N",
          "-X",
          "POST",
          "-H",
          "Content-Type: application/json",
          "-H",
          authorization,
          "-d",
          "@" .. data_file,
          required_params.url,
        }) do
          table.insert(_args, arg)
        end
      else
        local env = {
          url = required_params.url,
          LLM_KEY = LLM_KEY,
          body = body,
          authorization = authorization,
        }

        setmetatable(env, { __index = _G })
        _args = F.GetUserRequestArgs(opts.args, env)
      end

      if parse == nil then
        -- if url is set, but not set parse_handler, parse will be `zhipu` by default
        parse = function(chunk)
          ctx.assistant_output = chunk.choices[1].message.content
          return ctx.assistant_output
        end
      end
    end
    ctx.args = _args

    local job = require("plenary.job")
    local request_job = job:new({
      command = "curl",
      args = _args,
      on_stdout = schedule_wrap(function(_, data)
        ctx.line = ctx.line .. F.TrimLeadingWhitespace(data)
      end),
      on_stderr = schedule_wrap(function(_, err)
        if err ~= nil then
          LOG:ERROR(err)
        end
        -- TODO: Add error handling
      end),
      on_exit = schedule_wrap(function()
        if not validate_str_and_log_error(ctx.line) then
          return exit_callback(opts, ctx, waiting_state)
        end
        local success, result = pcall(json.decode, ctx.line)
        if success then
          ctx.assistant_output = parse(result)
        else
          LOG:ERROR("Error occurred:", result)
        end
        if ctx.body.tools ~= nil then
          backends.get_tools_respond(required_params.api_type, conf.configs, ctx)(ctx.line)
        end
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
      while waiting_state.box do
        waiting_state.timer:close()
        waiting_state.box:unmount()
        waiting_state.box = nil
      end
      LOG:ERROR(err)
    end
  end)()
end
return io_parse
