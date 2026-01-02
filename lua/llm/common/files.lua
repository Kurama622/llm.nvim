local state = require("llm.state")
local F = require("llm.common.api")

local files = {
  {
    label = "file",
    detail = "Quote the content of the file",
    kind_name = "llm.file",
    callback = function(bufnr, path, opts, chat_job)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      local file_ctx_tbl, start_line, start_col, end_line, end_col = F.GetVisualSelectionRange(bufnr)

      state.quote_files.file_info_list[bufnr] = {
        start_line = start_line,
        end_line = end_line,
        start_col = start_col,
        end_col = end_col,
        ft = ft,
      }

      state.input.attach_content = state.input.attach_content
        .. "\n- "
        .. path
        .. "\n```"
        .. ft
        .. "\n"
        .. F.GetVisualSelection(file_ctx_tbl)
        .. "\n```"

      if opts.enable_file_idx == #state.quote_files then
        local name = opts._name or "chat"

        if F.IsValid(opts.diagnostic) then
          state.input.attach_content = state.input.attach_content
            .. "\n"
            .. F.GetRangeDiagnostics(state.quote_files.file_info_list, opts)
        end

        table.insert(opts.body.messages, {
          role = "user",
          content = state.input.attach_content,
          type = "quote_files",
        })

        if F.IsValid(opts.lsp) then
          opts.lsp.bufnr_info_list = state.quote_files.file_info_list
          state.input.request_with_lsp = F.lsp_wrap(opts)
        end
        if state.input.request_with_lsp ~= nil then
          state.input.request_with_lsp(function()
            if F.IsValid(state.input.lsp_ctx.content) then
              table.insert(opts.body.messages, state.input.lsp_ctx)
              -- Do not display lsp information
              -- F.AppendLspMsg(state.llm.popup.bufnr, state.llm.popup.winid)
            end
            opts.args[#opts.args] = vim.json.encode(opts.body)
            chat_job:start()
            state.llm.worker.jobs[name] = chat_job

            F.ClearAttach()
          end)
        else
          opts.args[#opts.args] = vim.json.encode(opts.body)
          chat_job:start()
          state.llm.worker.jobs[name] = chat_job
        end
      end
    end,
    picker = function(self, complete)
      local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
      local has_snacks, snacks = pcall(require, "snacks")
      if has_fzf_lua then
        fzf_lua.files({
          actions = {
            default = function(selected)
              local file_list = {}
              if F.IsValid(selected) then
                for _, file in ipairs(selected) do
                  file = file:gsub("^[^%w%p]+%s*", "") --  remove the icon if the file_icon is enable
                  local buf = vim.fn.bufadd(file)
                  vim.fn.bufload(buf)
                  table.insert(file_list, file)
                  table.insert(state.quote_files, {
                    buf = buf,
                    file = file,
                    callback = function(_, opts, chat_job)
                      self.callback(_.buf, _.file, opts, chat_job)
                    end,
                  })
                end
              end
              complete(file_list)
            end,
          },
        })
      elseif has_snacks then
        snacks.picker.files({
          actions = {
            close = function()
              vim.api.startinsert()
            end,
            confirm = function(picker, selected)
              picker:close()
              picker.close = picker.init_opts.actions.close
              local file
              local file_list = {}
              if F.IsValid(picker:selected()) then
                for _, item in ipairs(picker:selected()) do
                  file = item.file
                  local buf = vim.fn.bufadd(file)
                  vim.fn.bufload(buf)
                  table.insert(file_list, file)
                  table.insert(state.quote_buffers, {
                    buf = buf,
                    file = file,
                    callback = function(_, opts, chat_job)
                      self.callback(_.buf, _.file, opts, chat_job)
                    end,
                  })
                end
              else
                file = selected.file
                local buf = vim.fn.bufadd(file)
                vim.fn.bufload(buf)
                table.insert(file_list, file)
                table.insert(state.quote_files, {
                  buf = buf,
                  file = file,
                  callback = function(_, opts, chat_job)
                    self.callback(_.buf, _.file, opts, chat_job)
                  end,
                })
              end
              complete(file_list)
            end,
          },
        })
      else
        local fio = require("llm.common.file_io")
        local files = fio.ScanDir(vim.uv.cwd())
        if F.IsValid(files) then
          vim.ui.select(files, {
            prompt = "files",
          }, function(choice)
            if not choice then
              return
            else
              file = choice
              local buf = vim.fn.bufadd(file)
              vim.fn.bufload(buf)
              table.insert(state.quote_files, {
                buf = buf,
                file = file,
                callback = function(_, opts, chat_job)
                  self.callback(_.buf, _.file, opts, chat_job)
                end,
              })

              complete({ file })
            end
          end)
          return
        end
        complete()
      end
    end,
  },
}
return files
