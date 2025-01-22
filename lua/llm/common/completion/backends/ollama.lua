local job = require("plenary.job")
local state = require("llm.state")
local utils = require("llm.common.completion.utils")
local LOG = require("llm.common.log")

local ollama = { name = "ollama" }

function ollama.parse(chunk, assistant_output)
  local success, err = pcall(function()
    assistant_output = chunk.response
  end)

  if success then
    return assistant_output
  else
    LOG:ERROR("Error occurred:" .. err)
    return ""
  end
end

function ollama.request(opts)
  utils.terminate_all_jobs()

  local body = {
    model = opts.model,
    stream = opts.stream,
  }
  if opts.fim then
    body["prompt"] = opts.prompt
    body["suffix"] = opts.suffix
  end

  local _args = {
    opts.url,
    "-N",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "--max-time",
    opts.timeout,
    "-d",
    vim.fn.json_encode(body),
  }

  for i = 1, opts.n_completions do
    local assistant_output = ""
    local new_job = job:new({
      command = "curl",
      args = _args,
      on_stdout = vim.schedule_wrap(function(_, data)
        if data == nil or data:sub(1, 1) ~= "{" then
          return
        end
        local success, result = pcall(vim.json.decode, data)
        if success then
          assistant_output = ollama.parse(result, assistant_output)
        else
          LOG:ERROR("Error occurred:" .. result)
        end
      end),
      on_exit = vim.schedule_wrap(function()
        if assistant_output ~= "" then
          state.completion.contents[i - 1] = assistant_output
          if opts.exit_handler then
            opts.exit_handler()
          end
        end
      end),
    })
    table.insert(state.completion.jobs, new_job)
    new_job:start()
  end
end

return ollama
