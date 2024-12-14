local M = {}

local conf = require("llm.config")
local job = require("plenary.job")
local F = require("llm.common.func")

function M.GetStreamingOutput(
  bufnr,
  winid,
  messages,
  fetch_key,
  url,
  model,
  api_type,
  args,
  streaming_handler,
  stdout_handler,
  stderr_handler,
  exit_handler
)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")

  if fetch_key ~= nil then
    LLM_KEY = fetch_key()
  end

  local authorization = "Authorization: Bearer " .. LLM_KEY

  if LLM_KEY == "NONE" then
    authorization = ""
  end

  if url == nil then
    url = conf.configs.url
  end

  local MODEL = conf.configs.model
  if model ~= nil then
    MODEL = model
  end

  local body = nil

  local line = ""
  local assistant_output = ""

  local stream_output = nil

  if streaming_handler then
    stream_output = function(chunk)
      return streaming_handler(chunk, line, assistant_output, bufnr, winid, F)
    end
  elseif api_type then
    if api_type == "workers-ai" then
      stream_output = function(chunk)
        return F.WorkersAiStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    elseif api_type == "zhipu" then
      stream_output = function(chunk)
        return F.ZhipuStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    elseif api_type == "openai" then
      stream_output = function(chunk)
        return F.OpenAIStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    end
  elseif conf.configs.streaming_handler then
    stream_output = function(chunk)
      return conf.configs.streaming_handler(chunk, line, assistant_output, bufnr, winid, F)
    end
  elseif conf.configs.api_type then
    if conf.configs.api_type == "workers-ai" then
      stream_output = function(chunk)
        return F.WorkersAiStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    elseif conf.configs.api_type == "zhipu" then
      stream_output = function(chunk)
        return F.ZhipuStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    elseif conf.configs.api_type == "openai" then
      stream_output = function(chunk)
        return F.OpenAIStreamingHandler(chunk, line, assistant_output, bufnr, winid)
      end
    end
  end

  local _args = nil
  if url ~= nil then
    body = {
      stream = true,
      model = MODEL,
      max_tokens = conf.configs.max_tokens,
      messages = messages,
    }

    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if args == nil then
      _args = {
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
      _args = args
    end

    if stream_output == nil then
      -- if url is set, but not set streaming_handler, stream_output will be `zhipu` by default
      stream_output = function(chunk)
        if not chunk then
          return
        end
        local tail = chunk:sub(-1, -1)
        if tail:sub(1, 1) ~= "}" then
          line = line .. chunk
        else
          line = line .. chunk

          local start_idx = line:find("data: ", 1, true)
          local end_idx = line:find("}}]}", 1, true)
          local json_str = nil

          while start_idx ~= nil and end_idx ~= nil do
            if start_idx < end_idx then
              json_str = line:sub(7, end_idx + 3)
            end
            local data = vim.fn.json_decode(json_str)
            assistant_output = assistant_output .. data.choices[1].delta.content
            F.WriteContent(bufnr, winid, data.choices[1].delta.content)

            if end_idx + 4 > #line then
              line = ""
              break
            else
              line = line:sub(end_idx + 4)
            end
            start_idx = line:find("data: ", 1, true)
            end_idx = line:find("}}]}", 1, true)
          end
        end
      end
    end
  else
    body = {
      stream = true,
      max_tokens = conf.configs.max_tokens,
      messages = messages,
    }
    if conf.configs.temperature ~= nil then
      body.temperature = conf.configs.temperature
    end

    if conf.configs.top_p ~= nil then
      body.top_p = conf.configs.top_p
    end

    if args == nil then
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
      _args = args
    end

    if stream_output == nil then
      -- if url is not set, stream_output will be `workers-ai` by default
      stream_output = function(chunk)
        if not chunk then
          return
        end
        local tail = chunk:sub(-1, -1)
        if tail:sub(1, 1) ~= "}" then
          line = line .. chunk
        else
          line = line .. chunk
          local json_str = line:sub(7, -1)
          local data = vim.fn.json_decode(json_str)
          assistant_output = assistant_output .. data.response
          F.WriteContent(bufnr, winid, data.response)
          line = ""
        end
      end
    end
  end
  local worker = { job = nil }
  worker.job = job:new({
    command = "curl",
    args = _args,
    on_stdout = vim.schedule_wrap(function(_, chunk)
      if conf.configs.streaming_handler ~= nil then
        assistant_output = stream_output(chunk)
      elseif api_type ~= nil then
        assistant_output = stream_output(chunk)
      else
        stream_output(chunk)
      end
      -- TODO: Add stdout handling
    end),
    on_stderr = function(_, err)
      if err ~= nil and err:sub(1, 4) == "curl" then
        print(err)
      end
      -- TODO: Add error handling
    end,
    on_exit = function()
      table.insert(messages, { role = "assistant", content = assistant_output })
      local newline_func = vim.schedule_wrap(function()
        F.NewLine(bufnr, winid)
      end)
      newline_func()
      worker.job = nil
      if exit_handler ~= nil then
        local callback_func = vim.schedule_wrap(function()
          exit_handler(assistant_output)
        end)
        callback_func()
      end
    end,
  })
  worker.job:start()

  return worker
end

return M
