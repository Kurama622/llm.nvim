# llm.nvim

Free large language model (LLM) support for Neovim based on [cloudflare](https://dash.cloudflare.com/).

You need sign up on [cloudflare](https://dash.cloudflare.com/) and get your account and API key. Then you will find all [models](https://developers.cloudflare.com/workers-ai/models/) on cloudflare, where the models labeled as beta are free.


## Screenshots
### Chat

![llm-chat](https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-chat-compress.png)

### Translate

![llm-translate](https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-translate-compress.png)

### Explain code

![llm-explain-code](https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-explain-code-compress.png)

## Installation

Set `ACCOUNT` and `LLM_KEY` in your zshrc or bashrc
```sh
export ACCOUNT=xxxxxxxx
export LLM_KEY=********
```

- lazy.nvim

```lua
  {
    "StubbornVegeta/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMUserDefineOp" },
    config = function()
      require("llm").setup({
        prompt = "请用中文回答问题",
        max_tokens = 512,
        model = "@cf/qwen/qwen1.5-14b-chat-awq",
        input_box_opts = {
          relative = "editor",
          position = {
            row = "85%",
            col = "50%",
          },
          size = {
            width = "70%",
            height = "5%",
          },
        },
        output_box_opts = {
          style = "float", -- float (default) | right | left | above | below
          relative = "win",
          position = {
            row = "35%",
            col = "50%",
          },
          size = {
            width = "70%",
            height = "65%",
          },
        },
        popwin_opts = {
          relative = "cursor",
          position = {
            row = -5,
            col = 10,
          },
          size = {
            width = "50%",
            height = 15,
          },
          enter = true,
          border = {
            style = "rounded",
            text = {
              top = " Explain ",
            },
          },
        },
        -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Submit"]  = { mode = "n", key = "<cr>" },
          ["Input:Cancel"]  = { mode = "n", key = "<C-c>" },
          ["Input:Resend"]  = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output window in "split" style.
          ["Output:Ask"]  = { mode = "n", key = "i" },
          ["Output:Cancel"]  = { mode = "n", key = "<C-c>" },
          ["Output:Resend"]  = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output and input windows in "float" style.
          ["Session:Toggle"] = { mode = "n", key = "<leader>ac" },
          ["Session:Close"]  = { mode = "n", key = "<esc>" },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ae", mode = "v", "<cmd>LLMUserDefineOp 请解释下面这段代码<cr>" },
      { "<leader>t", mode = "x", "<cmd>LLMUserDefineOp 英译汉<cr>" },
    },
  },
```
