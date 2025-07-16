local job = require("plenary.job")
local state = require("llm.state")
local LOG = require("llm.common.log")
local F = require("llm.common.api")

local cmds = {
  {
    label = "web_search",
    detail = "Web Search",
    callback = function(web_search_conf, msg, opts, chat_job)
      local body = web_search_conf.params
      body.query = msg[#msg].content

      local j = job:new({
        command = "curl",
        args = {
          "-s",
          "-X",
          "POST",
          web_search_conf.url,
          "-H",
          "Content-Type: application/json",
          "-H",
          "Authorization: Bearer " .. web_search_conf.fetch_key,
          "-d",
          vim.json.encode(body),
        },
        on_stdout = vim.schedule_wrap(function(_, data)
          -- LOG:INFO("start web search ...")
        end),
        on_stderr = vim.schedule_wrap(function(_, err)
          if err ~= nil then
            LOG:ERROR(err)
          end
          -- TODO: Add error handling
        end),
        on_exit = vim.schedule_wrap(function(j)
          local search_response = vim.json.decode(j:result()[1])
          local reference = search_response.results

          F.WriteContent(opts.bufnr, opts.winid, "\n> [!CITE] References\n")
          for _, item in pairs(reference) do
            F.WriteContent(opts.bufnr, opts.winid, "> - [" .. item.title .. "](" .. item.url .. ")\n")
          end
          F.WriteContent(opts.bufnr, opts.winid, "\n")
          if search_response.answer then
            -- table.insert(msg, {
            --   role = "user",
            --   content = "\nPlease answer the question based on the provided web search results:\n"
            --     .. search_response.answer,
            -- })
            msg[#msg].content = msg[#msg].content:gsub("@web_search", "")
              .. "\nPlease answer the question based on the provided web search results.\n\n---\nSearch results:\n"
              .. search_response.answer
          else
            -- local search_content = "\nPlease answer the question based on the provided web search results:\n"
            -- for idx, item in ipairs(reference) do
            --   search_content = search_content .. idx .. ". " .. item.content .. "\n"
            -- end
            -- table.insert(msg, {
            --   role = "user",
            --   content = search_content,
            -- })

            msg[#msg].content = msg[#msg].content:gsub("@web_search", "")
              .. "\nPlease answer the question based on the provided web search results:\n\n---\nSearch results:\n"
            for idx, item in ipairs(reference) do
              msg[#msg].content = msg[#msg].content .. idx .. ". " .. item.content .. "\n"
            end
          end
          -- update plenary job args
          opts.body.messages = msg
          opts.args[#opts.args] = vim.json.encode(opts.body)
          LOG:INFO("Finish web search!")
          table.remove(state.enabled_cmds, opts.enabled_cmds_idx)
        end),
      })

      LOG:INFO("start web search ...")
      job.chain(j, chat_job)
    end,
  },
  { label = "cmdtest", detail = "Test Cmds", callback = function() end },
}
return cmds
