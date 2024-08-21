local M = {}

local conf = require("llm.config")
local job = require("plenary.job")
local F = require("llm.common.func")

function M.GetStreamingOutput(bufnr, winid, messages)
  local ACCOUNT = os.getenv("ACCOUNT")
  local LLM_KEY = os.getenv("LLM_KEY")
  local MODEL = conf.configs.model

  local body = {
    stream = true,
    max_tokens = conf.configs.max_tokens,
    messages = messages,
  }

  local line = ""
  local system_output = ""
  local stream_output = function(chunk)
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

  active_job = job:new({
    command = "curl",
    args = {
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
    },
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
