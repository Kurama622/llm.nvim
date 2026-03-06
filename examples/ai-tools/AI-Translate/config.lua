Translate = {
  handler = "qa_handler",
  opts = {
    component_width = "60%",
    component_height = "50%",
    query = {
      title = " 󰊿 Trans ",
      hl = { link = "Define" },
    },
    input_box_opts = {
      size = "15%",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
    preview_box_opts = {
      size = "85%",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },

    -- Customize the behavior of accept (default keymap: y/Y),
    -- the default action of copying text will include a newline character at the end.
    -- This sample code copies text without the trailing newline character.
    accept = {
      action = function(self, opts)
        local res = vim.tbl_filter(function(item)
          return item ~= ""
        end, vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, true))

        vim.fn.setreg("+", table.concat(res, "\n"))
      end,
    },
  },
},
