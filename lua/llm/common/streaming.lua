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
  local system_output = ""

  local stream_output = nil
  local _args = nil
  if conf.configs.url ~= nil then
    body = {
      stream = true,
      model = MODEL,
      max_tokens = conf.configs.max_tokens,
      messages = messages,
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
          system_output = system_output .. data.choices[1].delta.content
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
        system_output = system_output .. data.response
        F.WriteContent(bufnr, winid, data.response)
        line = ""
      end
    end
  end
  active_job = job:new({
    command = "curl",
    args = _args,
    on_stdout = vim.schedule_wrap(function(_, chunk)
      stream_output(chunk)
    end),
    on_stderr = function(_, err)
      if err ~= nil and err:sub(1, 4) == "curl" then
        print(err)
      end
      active_job = nil
    end,
    on_exit = function()
      active_job = nil
      table.insert(messages, { role = "assistant", content = system_output })
      local newline_func = vim.schedule_wrap(function()
        F.NewLine(bufnr, winid)
      end)
      newline_func()
    end,
  })
  active_job:start()
  return active_job
end

return M
--   
