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

  local fetch_key = opts.fetch_key or conf.configs.fetch_key
  if fetch_key ~= nil then
    LLM_KEY = fetch_key()
  end
  local authorization = "Authorization: Bearer " .. LLM_KEY

  local url = opts.url or conf.configs.url
  local MODEL = opts.model or conf.configs.model
  local api_type = opts.api_type or conf.configs.api_type
  local parse_handler = opts.parse_handler or conf.configs.parse_handler
  local keep_alive = opts.keep_alive or conf.configs.keep_alive
  local temperatrue = opts.temperature or conf.configs.temperature
  local top_p = opts.top_p or conf.configs.top_p
  local max_tokens = opts.max_tokens or conf.configs.max_tokens

  local body = {
    stream = false,
    max_tokens = max_tokens,
    messages = opts.messages,
  }

  if keep_alive then
    body.keep_alive = keep_alive
  end

  if temperatrue then
    body.temperature = temperatrue
  end

  if top_p then
    body.top_p = top_p
  end

  local ctx = {
    assistant_output = "",
  }

  local parse = backends.get_parse_handler(parse_handler, api_type, conf.configs, ctx)
  local _args = nil
  if url ~= nil then
    body.model = MODEL

    if opts.args == nil then
      _args = {
        "-s",
        url,
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
        url = url,
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
      _args = {
        "-s",
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
          LOG:ERROR("Error occurred:" .. result)
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
