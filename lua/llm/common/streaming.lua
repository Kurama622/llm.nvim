local M = {}

local conf = require("llm.config")
local job = require("plenary.job")
local F = require("llm.common.func")

function M.GetStreamingOutput(bufnr, winid, messages)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")
  local MODEL = conf.configs.model

  local body = nil

  local line = ""
  local assistant_output = ""

  local stream_output = nil

  if conf.configs.streaming_handler ~= nil then
    stream_output = function(chunk)
      return conf.configs.streaming_handler(chunk, line, assistant_output, bufnr, winid, F)
    end
  end

  local _args = nil
  if conf.configs.url ~= nil then
    body = {
      stream = true,
      model = MODEL,
      max_tokens = conf.configs.max_tokens,
      messages = messages,
      temperature = conf.configs.temperature,
    }
    _args = {
      conf.configs.url,
      "-N",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. LLM_KEY,
      "-d",
      vim.fn.json_encode(body),
    }

    -- TODO: Allow users to customize stream processing functions
    if stream_output == nil then
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
    _args = {
      string.format("https://api.cloudflare.com/client/v4/accounts/%s/ai/run/%s", ACCOUNT, MODEL),
      "-N",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. LLM_KEY,
      "-d",
      vim.fn.json_encode(body),
    }

    if stream_output == nil then
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
      else
        stream_output(chunk)
      end
    end),
    on_stderr = function(_, err)
      if err ~= nil and err:sub(1, 4) == "curl" then
        print(err)
      end
    end,
    on_exit = function()
      table.insert(messages, { role = "assistant", content = assistant_output })
      local newline_func = vim.schedule_wrap(function()
        F.NewLine(bufnr, winid)
      end)
      newline_func()
      worker.job = nil
    end,
  })
  worker.job:start()

  return worker
end

return M
