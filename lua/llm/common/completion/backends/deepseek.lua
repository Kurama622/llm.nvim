local job = require("plenary.job")
local state = require("llm.state")
local utils = require("llm.common.completion.utils")
local LOG = require("llm.common.log")

local deepseek = {}

function deepseek.parse(chunk, assistant_output)
  local success, err = pcall(function()
    assistant_output = chunk.choices[1].text
  end)

  if success then
    return assistant_output
  else
    LOG:ERROR("err:", err, "chunk:", chunk)
    return ""
  end
end

function deepseek.request(opts)
  utils.terminate_all_jobs()
  if state.completion.frontend.name == "cmp" then
    state.completion.contents = {}
  end
  local LLM_KEY = os.getenv("LLM_KEY")
  local body = {
    model = opts.model,
    stream = opts.stream,
  }
  if opts.fim then
    body["prompt"] = opts.prompt
    body["suffix"] = opts.suffix
  end
  if opts.max_tokens then
    body["max_tokens"] = opts.max_tokens
  end

  if opts.fetch_key ~= nil then
    LLM_KEY = opts.fetch_key()
  end

  local authorization = "Authorization: Bearer " .. LLM_KEY

  local _args = {
    "-L",
    "-s",
    opts.url,
    "-N",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    authorization,
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
          assistant_output = deepseek.parse(result, assistant_output)
        else
          LOG:ERROR("Error occurred:", result)
        end
      end),
      on_exit = vim.schedule_wrap(function()
        if assistant_output and assistant_output ~= "" then
          LOG:TRACE("Assistant output:", assistant_output)
          state.completion.contents[i] = assistant_output
          if opts.exit_handler then
            if state.completion.frontend.name == "blink" then
              opts.exit_handler({ state.completion.contents[i] })
            else
              opts.exit_handler(state.completion.contents)
            end
          end
        end
      end),
    })
    table.insert(state.completion.jobs, new_job)
    new_job:start()
  end
end

return deepseek
