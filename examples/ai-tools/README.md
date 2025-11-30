# Example of AI Tools Configuration

You can place the configuration of the tools you need in the `app_handler`.


- [AI-Commit-Messages](./AI-Commit-Messages/config.lua)
- [AI-Translate](./AI-Translate/config.lua)
- [Ask](./Ask/config.lua)
- [Attach-To-Chat](./Attach-To-Chat/config.lua)
- [Code-Explain](./Code-Explain/config.lua)
- [Generate-Test-Cases](./Generate-Test-Cases/config.lua)
- [Optimize-Code](./Optimize-Code/config.lua)
- [Optimize-Code-and-Display-Diff](./Optimize-Code-and-Display-Diff/config.lua)
- [Word-Translate](./Word-Translate/config.lua)
- [Formula-Recognition](./Formula-Recognition/README.md)
- [Generate-Docstring](./Generate-Docstring/config.lua)
- [Function-Calling](./Function-calling/README.md)
- [Code-Completions](./Code-Completions)


```lua
return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      require("llm").setup({
        -- [[ Github Models ]]
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o",
        api_type = "openai",
        max_tokens = 8000,
        temperature = 0.3,
        top_p = 0.7,

        prompt = "You are a helpful chinese assistant.",

        spinner = {
          text = {
            "󰧞󰧞",
            "󰧞󰧞",
            "󰧞󰧞",
            "󰧞󰧞",
          },
          hl = "Title",
        },

        prefix = {
          user = { text = "😃 ", hl = "Title" },
          assistant = { text = "  ", hl = "Added" },
        },

        -- history_path = "/tmp/llm-history",
        save_session = true,
        max_history = 15,
        max_history_name_length = 20,

        -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Submit"]      = { mode = "n", key = "<cr>" },
          ["Input:Cancel"]      = { mode = {"n", "i"}, key = "<C-c>" },
          ["Input:Resend"]      = { mode = {"n", "i"}, key = "<C-r>" },

          -- only works when "save_session = true"
          ["Input:HistoryNext"] = { mode = {"n", "i"}, key = "<C-j>" },
          ["Input:HistoryPrev"] = { mode = {"n", "i"}, key = "<C-k>" },

          -- The keyboard mapping for the output window in "split" style.
          ["Output:Ask"]        = { mode = "n", key = "i" },
          ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
          ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output and input windows in "float" style.
          ["Session:Toggle"]    = { mode = "n", key = "<leader>ac" },
          ["Session:Close"]     = { mode = "n", key = {"<esc>", "Q"} },
        },

        -- display diff [require by action_handler]
        display = {
          diff = {
            layout = "vertical", -- vertical|horizontal split for default provider
            opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
            provider = "mini_diff", -- default|mini_diff
            disable_diagnostic = true, -- Whether to show diagnostic information when displaying diff
          },
        },
        app_handler = {
          -- Your AI tools Configuration
          -- TOOL_NAME = { ... }
          ...
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      -- Your AI Tools Key mappings
      { "<leader>ts", mode = "x", "<cmd>LLMAppHandler WordTranslate<cr>" },
      --    |                 |                             |
      -- your key mapping  your mode                    tool name
    },
  },
}
```
