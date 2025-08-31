return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      require("llm").setup({
        prefix = {
          user = { text = "  ", hl = "Title" },
          assistant = { text = "  ", hl = "Added" },
        },
        style = "right", -- right | left | top | bottom
        chat_ui_opts = {
          input = {
            split = {
              relative = "win",
              position = {
                row = "80%",
                col = "50%",
              },
              border = {
                text = {
                  top = "  Enter Your Question ",
                  top_align = "center",
                },
              },
              win_options = {
                winblend = 0,
                winhighlight = "Normal:String,FloatBorder:LlmYellowLight,FloatTitle:LlmYellowNormal",
              },
              size = { height = 2, width = "80%" },
            },
          },
          output = {
            split = {
              size = "40%",
            },
          },
          history = {
            split = {
              size = "60%",
            },
          },
          models = {
            split = {
              relative = "win",
              size = { height = "30%", width = "60%" },
            },
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

          -- move popwin
          move = {
            left = {
              mode = "n",
              keys = "<left>",
              distance = 5,
            },
            right = {
              mode = "n",
              keys = "<right>",
              distance = 5,
            },
            up = {
              mode = "n",
              keys = "<up>",
              distance = 2,
            },
            down = {
              mode = "n",
              keys = "<down>",
              distance = 2,
            },
          },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  },
}
