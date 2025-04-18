local M = {}

local conf = require("llm.config")
local job = require("plenary.job")
local F = require("llm.common.api")
local backends = require("llm.backends")
local state = require("llm.state")
local LOG = require("llm.common.log")

function M.GetStreamingOutput(opts)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")

  local fetch_key = opts.fetch_key
    or conf.configs.fetch_key
    or (conf.configs.models and conf.configs.models[1].fetch_key or nil)
  if fetch_key ~= nil then
    LLM_KEY = fetch_key()
  end

  local authorization = "Authorization: Bearer " .. LLM_KEY

  if LLM_KEY == "NONE" then
    authorization = ""
  end

  local url = opts.url or conf.configs.url or (conf.configs.models and conf.configs.models[1].url or nil)
  local MODEL = opts.model or conf.configs.model or (conf.configs.models and conf.configs.models[1].model or nil)
  local api_type = opts.api_type
    or conf.configs.api_type
    or (conf.configs.models and conf.configs.models[1].api_type or nil)
  local streaming_handler = opts.streaming_handler
    or conf.configs.streaming_handler
    or (conf.configs.models and conf.configs.models[1].streaming_handler or nil)
  local keep_alive = opts.keep_alive
    or conf.configs.keep_alive
    or (conf.configs.models and conf.configs.models[1].keep_alive or nil)
  local temperatrue = opts.temperature
    or conf.configs.temperature
    or (conf.configs.models and conf.configs.models[1].temperatrue or nil)
  local top_p = opts.top_p or conf.configs.top_p or (conf.configs.models and conf.configs.models[1].top_p or nil)
  local max_tokens = opts.max_tokens
    or conf.configs.max_tokens
    or (conf.configs.models and conf.configs.models[1].max_tokens or nil)

  local body = {
    stream = true,
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
    line = "",
    assistant_output = "",
    bufnr = opts.bufnr,
    winid = opts.winid,
  }
  local stream_output = backends.get_streaming_handler(streaming_handler, api_type, conf.configs, ctx)

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
  local worker = { job = nil }
  worker.job = job:new({
    command = "curl",
    args = _args,
    on_stdout = vim.schedule_wrap(function(_, chunk)
      if api_type or streaming_handler then
        ctx.assistant_output = stream_output(chunk)
      else
        stream_output(chunk)
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
      table.insert(opts.messages, { role = "assistant", content = ctx.assistant_output })
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
    end),
  })
  worker.job:start()

  return worker
end

return M
