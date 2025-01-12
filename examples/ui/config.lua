local Text = require("nui.text")
return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      require("llm").setup({
        chat_ui_opts = {
          relative = "editor",
          position = "50%",
          size = {
            width = "80%",
            height = "80%",
          },
          input = {
            relative = "editor", -- for split style
            position = {
              row = "80%", -- for split style
              col = "50%",
            },
            enter = true,
            focusable = true,
            zindex = 50,
            border = {
              style = "rounded",
              text = {
                top = Text(" Enter Your Question ", "String"),
                top_align = "center",
              },
            },
            win_options = {
              winblend = 0,
              winhighlight = "Normal:Normal,FloatBorder:Float",
            },
            size = { row = "10%", col = "80%" },
            order = 2,
          },
          output = {
            enter = true,
            focusable = true,
            zindex = 50,
            border = {
              style = "rounded",
              text = {
                top = " Preview ",
                top_align = "center",
              },
            },
            win_options = {
              winblend = 0,
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
            size = { row = "90%", col = "80%" },
            order = 1,
          },
          zindex = 50,
          history = {
            enter = false,
            focusable = false,
            max_width = 20,
            border = {
              style = "rounded",
              text = {
                top = " History ",
                top_align = "center",
              },
            },
            win_options = {
              winblend = 0,
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
            size = { row = "100%", col = "20%" },
            order = 3,
          },
        },
        -- popup window options
        popwin_opts = {
          relative = "cursor",
          enter = true,
          focusable = true,
          zindex = 50,
          position = { row = -7, col = 15 },
          size = { height = 15, width = "50%" },
          border = { style = "single", text = { top = " Explain ", top_align = "center" } },
          win_options = {
            winblend = 0,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  },
}
