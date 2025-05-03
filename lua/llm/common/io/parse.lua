local Popup = require("nui.popup")
local conf = require("llm.config")
local ui = require("llm.common.ui")
local api = require("llm.common.api")
local backends = require("llm.backends")
local job = require("plenary.job")
local LOG = require("llm.common.log")
local state = require("llm.state")
local io_utils = require("llm.common.io.utils")

local io_parse = {
  required_params = {},
}
function io_parse.GetOutput(opts)
  local wait_box_opts = ui.wait_ui_opts()
  local wait_box = Popup(wait_box_opts)

  local waiting_state = {
    box = wait_box,
    box_opts = wait_box_opts,
    bufnr = wait_box.bufnr,
    winid = wait_box.winid,
    finish = false,
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

  -- Non-streaming output disable thinking
  required_params.enable_thinking = false

  if required_params.fetch_key ~= nil then
    LLM_KEY = required_params.fetch_key()
  end
  local authorization = "Authorization: Bearer " .. LLM_KEY

  local body = {
    stream = false,
    messages = opts.messages,
  }

  local params = {
    max_tokens = required_params.max_tokens,
    keep_alive = required_params.keep_alive,
    temperatrue = required_params.temperatrue,
    top_p = required_params.top_p,
    enable_thinking = required_params.enable_thinking,
  }
  for param_name, param_value in pairs(params) do
    io_utils.add_request_body_params(body, param_name, param_value)
  end

  local ctx = {
    assistant_output = "",
  }

  local parse = backends.get_parse_handler(required_params.parse_handler, required_params.api_type, conf.configs, ctx)
  local _args = nil
  if required_params.url ~= nil then
    body.model = required_params.model

    if opts.args == nil then
      _args = {
        "-s",
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
  else
    if opts.args == nil then
      LOG:WARN(
        "[Deprecated Usage] Please configure the url (Note: For cloudflare, you should use https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s"
      )
      _args = {
        "-s",
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
        LLM_KEY = LLM_KEY,
        body = body,
        authorization = authorization,
      }

      setmetatable(env, { __index = _G })
      _args = api.GetUserRequestArgs(opts.args, env)
    end

    if parse == nil then
      -- if url is not set, parse will be `workers-ai` by default
      parse = function(chunk)
        ctx.assistant_output = chunk.response
        return ctx.assistant_output
      end
    end
  end

  job
    :new({
      command = "curl",
      args = _args,
      on_stdout = vim.schedule_wrap(function(_, data)
        local str = api.TrimLeadingWhitespace(data)
        local prefix = str:sub(1, 1)
        if prefix ~= "{" then
          if prefix ~= "" then
            LOG:ERROR(data)
          end
          return
        end
        local success, result = pcall(vim.json.decode, str)
        if success then
          ctx.assistant_output = parse(result)
        else
          LOG:ERROR("Error occurred:", result)
        end
      end),
      on_stderr = function(_, err)
        if err ~= nil then
          LOG:ERROR(err)
        end
        -- TODO: Add error handling
      end,
      on_exit = vim.schedule_wrap(function()
        table.insert(opts.messages, { role = "assistant", content = ctx.assistant_output })
        waiting_state.box:unmount()
        waiting_state.finish = true
        if opts.exit_handler ~= nil then
          local callback_func = vim.schedule_wrap(function()
            opts.exit_handler(ctx.assistant_output)
          end)
          callback_func()
        end
      end),
    })
    :start()
end
return io_parse
