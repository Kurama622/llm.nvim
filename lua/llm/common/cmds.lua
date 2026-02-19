local job = require("plenary.job")
local state = require("llm.state")
local LOG = require("llm.common.log")
local F = require("llm.common.api")
local conf = require("llm.config")
local backends = require("llm.backends")

local function setup_web_search_job(web_search_conf, fetch_key, opts, body, msg, co)
  return job:new({
    command = "curl",
    args = {
      "-s",
      "-X",
      "POST",
      web_search_conf.url,
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. fetch_key,
      "-d",
      vim.json.encode(body),
    },
    on_stdout = vim.schedule_wrap(function(_, data)
      require("llm.common.ui").clear_spinner_extmark(opts)
    end),
    on_stderr = vim.schedule_wrap(function(_, err)
      if err ~= nil then
        LOG:ERROR(err)
      end
      -- TODO: Add error handling
    end),
    on_exit = vim.schedule_wrap(function(j)
      local status, search_response = pcall(vim.json.decode, j:result()[1])
      if not status or not search_response.results then
        return
      end
      local reference = search_response.results

      F.WriteContent(opts.bufnr, opts.winid, "\n> [!CITE] References\n")
      for _, item in pairs(reference) do
        F.WriteContent(opts.bufnr, opts.winid, "> - [" .. item.title .. "](" .. item.url .. ")\n")
      end
      F.WriteContent(opts.bufnr, opts.winid, "\n")
      if F.IsValid(search_response.answer) then
        msg[#msg].content = body.query
          .. "\nPlease answer the question based on the provided web search results.\n\n---\nSearch results:\n"
          .. search_response.answer
      else
        msg[#msg].content = body.query
          .. "\nPlease answer the question based on the provided web search results:\n\n---\nSearch results:\n"
        for idx, item in ipairs(reference) do
          msg[#msg].content = msg[#msg].content .. idx .. ". " .. item.content .. "\n"
        end
      end
      -- update plenary job args
      opts.body.messages = msg
      require("llm.common.file_io").SaveFile(opts.request_body_file, vim.json.encode(opts.body))
      LOG:INFO("Finish search!")

      require("llm.common.ui").display_spinner_extmark(opts)
      state.llm.worker.jobs.web_search = nil
      table.remove(state.enabled_cmds, opts.enabled_cmds_idx)
      coroutine.resume(co)
    end),
  })
end
local cmds = {
  {
    label = "web_search",
    detail = "Search the web for information",
    callback = function(web_search_conf, msg, opts, co)
      local body = web_search_conf.params
      local prompt = type(web_search_conf.prompt) == "function" and web_search_conf.prompt()
        or web_search_conf.prompt
        or [[You are given a multi-turn conversation between a user and an assistant. The user may ask multiple questions across different turns. Some of these questions have already been answered correctly and acknowledged by the user, so they can be ignored. Other questions may have been answered incorrectly, incompletely, or with outdated information. The user now wants to enable a web search to get the correct answer.

Your task: Identify the single question that the user most likely wants to search for based on the conversation.

Output **ONLY THE QUESTION ITSELF**, in plain text, **WITH NO ADDITIONAL EXPLANATION**.]]

      local fetch_key = ""
      if type(web_search_conf.fetch_key) == "function" then
        fetch_key = web_search_conf.fetch_key()
      elseif type(web_search_conf.fetch_key) == "string" then
        fetch_key = web_search_conf.fetch_key
      end

      if #msg > 2 then
        local messages = {
          {
            role = "system",
            content = prompt,
          },
        }
        for i, _ in ipairs(msg) do
          if i > 1 and i ~= #msg then
            table.insert(messages, msg[i])
          elseif i == #msg then
            table.insert(messages, {
              role = "user",
              content = msg[#msg].content:gsub("@web_search", ""),
            })
          end
        end
        local query_summarize_body = vim.deepcopy(opts.body)
        query_summarize_body.messages = messages
        local query_summarize_args = {}
        for i, arg in ipairs(opts.args) do
          if i ~= #opts.args then
            table.insert(query_summarize_args, arg)
          end
        end
        -- update curl request body file
        require("llm.common.file_io").SaveFile(opts.request_body_file, vim.json.encode(query_summarize_body))

        local query_summarize_job = job:new({
          command = "curl",
          args = query_summarize_args,
          on_exit = vim.schedule_wrap(function(query_summarize_job)
            body.query = backends.get_streaming_tbl_handler(opts.api_type, conf.configs)(query_summarize_job:result())
            LOG:INFO("Start search ...")
            local j = setup_web_search_job(web_search_conf, fetch_key, opts, body, msg, co)
            j:start()
            state.llm.worker.jobs.web_search = j
          end),
        })
        query_summarize_job:start()
      else
        body.query = msg[#msg].content:gsub("@web_search", "")
        LOG:INFO("Start search ...")
        local j = setup_web_search_job(web_search_conf, fetch_key, opts, body, msg, co)
        j:start()
        state.llm.worker.jobs.web_search = j
      end
      coroutine.yield()
    end,
  },
}
return cmds
