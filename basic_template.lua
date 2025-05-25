return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      local tools = require("llm.tools") -- for app tools
      require("llm").setup({
        prompt = "You are a professional programmer.",

        ------------------- set your model parameters -------------------
        -- You can choose to configure multiple models as needed.
        -----------------------------------------------------------------

        --- style1: set single model parameters
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o-mini",
        api_type = "openai",

        -- style2: set parameters of multiple models
        -- (If you need to use multiple models and frequently switch between them.)
        models = {
          {
            name = "ChatGPT",
            url = "https://models.inference.ai.azure.com/chat/completions",
            model = "gpt-4o-mini",
            api_type = "openai",
          },
          {
            name = "ChatGLM",
            url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            model = "glm-4-flash",
            api_type = "zhipu",
            max_tokens = 8000,
            fetch_key = function()
              return vim.env.GLM_KEY
            end,
            temperature = 0.3,
            top_p = 0.7,
          },
        },

        ---------------- set your keymaps for interaction ---------------
        keys = {
          ["Input:Submit"] = { mode = "n", key = "<cr>" },
          ["Input:Cancel"] = { mode = { "n", "i" }, key = "<C-c>" },
          ["Input:Resend"] = { mode = { "n", "i" }, key = "<C-r>" },

          -- ...
        },

        ---------------------- set your app tools  ----------------------
        app_handler = {
          OptimCompare = {
            handler = tools.action_handler,
            opts = {
              fetch_key = function()
                return vim.env.GITHUB_TOKEN
              end,
              url = "https://models.inference.ai.azure.com/chat/completions",
              model = "gpt-4o-mini",
              api_type = "openai",
              language = "Chinese",
            },
            ["Your Tool Name"] = {
              -- handler =
              -- opts = {
              --    fetch_key = function() return <your api key> end
              -- }
              -- url = "https://xxx",
              -- model = "xxx"
              -- api_type = ""
            },
            -- ...
          },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ao", mode = "x", "<cmd>LLMAppHandler OptimCompare<cr>", desc = " Optimize the Code" },
    },
  },
}
