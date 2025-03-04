local Popup = require("nui.popup")
local conf = require("llm.config")
local ui = require("llm.common.ui")
local api = require("llm.common.api")
local backends = require("llm.backends")
local job = require("plenary.job")
local LOG = require("llm.common.log")

local io_parse = {}
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

  if opts.fetch_key ~= nil then
    LLM_KEY = opts.fetch_key()
  end

  if opts.url == nil then
    opts.url = conf.configs.url
  end

  local MODEL = conf.configs.model
  if opts.model ~= nil then
    MODEL = opts.model
  end

  local body = nil
  local authorization = "Authorization: Bearer " .. LLM_KEY

  local ctx = {
    assistant_output = "",
  }

  local parse = backends.get_parse_handler(opts.parse_handler, opts.api_type, conf.configs, ctx)
  local _args = nil
  if opts.url ~= nil then
    body = {
      model = MODEL,
      max_tokens = conf.configs.max_tokens,
      messages = opts.messages,
      stream = false,
    }

    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if opts.args == nil then
      _args = {
        opts.url,
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
        url = opts.url,
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
    body = {
      max_tokens = conf.configs.max_tokens,
      messages = opts.messages,
    }
    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if opts.args == nil then
      _args = {
        string.format("https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s", ACCOUNT, MODEL),
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
        MODEL = MODEL,
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
        local str = api.trim_leading_whitespace(data)
        if str:sub(1, 1) ~= "{" then
          return
        end
        local success, result = pcall(vim.json.decode, str)
        if success then
          ctx.assistant_output = parse(result)
        else
          LOG:ERROR("Error occurred:" .. result)
        end
      end),
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
