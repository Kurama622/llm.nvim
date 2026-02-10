local buffers = {
  {
    label = "buffer",
    detail = "Quote the content of the buffer",
    kind_name = "llm.buffer",
    callback = function(bufnr, opts, co)
      local state = require("llm.state")
      local F = require("llm.common.api")

      local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      local buffer_ctx_tbl, start_line, start_col, end_line, end_col = F.GetVisualSelectionRange(bufnr)

      state.quote_buffers.buffer_info_list[bufnr] = {
        start_line = start_line,
        end_line = end_line,
        start_col = start_col,
        end_col = end_col,
        ft = ft,
      }

      state.input.attach_content = state.input.attach_content
        .. "\n- buffer("
        .. bufnr
        .. ")\n```"
        .. ft
        .. "\n"
        .. F.GetVisualSelection(buffer_ctx_tbl)
        .. "\n```"

      if opts.enable_buffer_idx == #state.quote_buffers then
        if F.IsValid(opts.diagnostic) then
          state.input.attach_content = state.input.attach_content
            .. "\n"
            .. F.GetRangeDiagnostics(state.quote_buffers.buffer_info_list, opts)
        end

        table.insert(opts.body.messages, {
          role = "user",
          content = state.input.attach_content,
          type = "quote_buffers",
        })

        if F.IsValid(opts.lsp) then
          opts.lsp.bufnr_info_list = state.quote_buffers.buffer_info_list
          state.input.request_with_lsp = F.lsp_wrap(opts)
        end
        if state.input.request_with_lsp ~= nil then
          state.input.request_with_lsp(function()
            opts.args[#opts.args] = vim.json.encode(opts.body)
            coroutine.resume(co)
          end)
        else
          vim.schedule(function()
            opts.args[#opts.args] = vim.json.encode(opts.body)
            coroutine.resume(co)
          end)
        end
        coroutine.yield()
      end
    end,
    picker = function(self, complete)
      local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
      local has_snacks, snacks = pcall(require, "snacks")
      if has_fzf_lua then
        fzf_lua.buffers({
          actions = {
            default = function(selected)
              local buf, file
              local buf_list = {}
              if F.IsValid(selected) then
                for _, item in ipairs(selected) do
                  -- 注意这中间的空白是特殊空格，实际可以复制粘贴替换
                  local str = item:gsub(" ", " ")
                  local parts = vim.split(str, "%s+")
                  buf = tonumber(parts[1]:match("%w+"))
                  file = parts[3]:match("^(.-):%w+")
                  table.insert(buf_list, buf)
                  table.insert(state.quote_buffers, {
                    buf = buf,
                    file = file,
                    callback = function(_, opts, chat_job)
                      self.callback(_.buf, opts, chat_job)
                    end,
                  })
                end
              end
              complete(buf_list)
            end,
          },
        })
      elseif has_snacks then
        snacks.picker.buffers({
          actions = {
            close = function()
              vim.api.startinsert()
            end,
            confirm = function(picker, selected)
              picker:close()
              picker.close = picker.init_opts.actions.close
              local buf, file
              local buf_list = {}
              if F.IsValid(picker:selected()) then
                for _, item in ipairs(picker:selected()) do
                  buf = item.buf
                  file = item.file:gsub(" ", "\\ ")
                  table.insert(buf_list, buf)
                  table.insert(state.quote_buffers, {
                    buf = buf,
                    file = file,
                    callback = function(_, opts, chat_job)
                      self.callback(_.buf, opts, chat_job)
                    end,
                  })
                end
              else
                buf = selected.buf
                file = selected.file:gsub(" ", "\\ ")
                table.insert(buf_list, buf)
                table.insert(state.quote_buffers, {
                  buf = buf,
                  file = file,
                  callback = function(_, opts, chat_job)
                    self.callback(_.buf, opts, chat_job)
                  end,
                })
              end
              complete(buf_list)
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
                buf = tonumber(choice.buf),
                file = choice.file,
                callback = function(_, opts, chat_job)
                  self.callback(_.buf, opts, chat_job)
                end,
              })

              complete({ choice.buf })
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
