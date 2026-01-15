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
    -- with the default action being entering visual-line mode to copy.
    -- This sample code is for entering the visual mode to copy.
    accept = {
      action = function(self, opts)
        vim.api.nvim_set_current_win(opts.winid)
        vim.api.nvim_command("normal! gg^vGkk$hy")
      end,
    },
  },
},
