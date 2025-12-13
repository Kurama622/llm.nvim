local state = require("llm.state")
local F = require("llm.common.api")

local buffers = {
  {
    label = "buffer",
    detail = "Quote the content of the buffer",
    callback = function() end,
    picker = function(complete)
      local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
      local has_snacks, snacks = pcall(require, "snacks")
      if has_fzf_lua then
        fzf_lua.buffers({
          actions = {
            default = function(selected)
              local buf, file
              if F.IsValid(selected) then
                -- 注意这中间的空白是特殊空格，实际可以复制粘贴替换
                local str = selected[1]:gsub(" ", " ")

                local parts = vim.split(str, "%s+")
                buf = parts[1]:match("%w+")
                file = parts[3]:match("^(.-):%w+")
                table.insert(state.quote_buffers, {
                  buf = buf,
                  file = file,
                })
              end
              complete(buf)
            end,
          },
        })
      elseif has_snacks then
        snacks.picker.buffers({
          actions = {
            confirm = function(picker, v)
              picker:close()
              table.insert(state.quote_buffers, {
                buf = v.buf,
                file = v.file:gsub(" ", "\\ "),
              })
              complete(v.buf)
            end,
          },
        })
      else
        local buffers = vim.tbl_map(function(v)
          if F.IsValid(v) then
            local parts = vim.split(v, "%s+")

            return {
              buf = parts[2],
              file = parts[4],
            }
          end
        end, vim.split(vim.api.nvim_exec2("buffers", { output = true }).output, "\n"))

        if F.IsValid(buffers) then
          vim.ui.select(buffers, {
            prompt = "buffers",
            format_item = function(v)
              return "[" .. v.buf .. "]\t" .. v.file
            end,
          }, function(choice)
            if not choice then
              return
            else
              table.insert(state.quote_buffers, {
                buf = choice.buf,
                file = choice.file,
              })

              complete(choice.buf)
            end
          end)
          return
        end
        complete()
      end
    end,
  },
}
return buffers
