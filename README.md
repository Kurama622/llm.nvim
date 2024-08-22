# llm.nvim

Free large language model (LLM) support for Neovim based on [cloudflare](https://dash.cloudflare.com/).

You need sign up on [cloudflare](https://dash.cloudflare.com/) and get your account and API key. Then you will find all [models](https://developers.cloudflare.com/workers-ai/models/) on cloudflare, where the models labeled as beta are free.


## Screenshots

<p align= "center">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" height="280">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-translate-compress.png" alt="llm-translate" height="280">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" height="280">
</p>

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
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        prompt = "请用中文回答问题",
        max_tokens = 512,
        model = "@cf/qwen/qwen1.5-14b-chat-awq",
        prefix = {
          user = { text = "😃 ", hl = "Title" },
          assistant = { text = "⚡ ", hl = "Added" },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ae", mode = "v", "<cmd>LLMSelectedTextHandler 请解释下面这段代码<cr>" },
      { "<leader>t", mode = "x", "<cmd>LLMSelectedTextHandler 英译汉<cr>" },
    },
  },
```

## Configuration

`llm.nvim` comes with the following defaults, you can override them by passing config as setup param

https://github.com/StubbornVegeta/llm.nvim/blob/f8e4383a5970696802439928c333c634e51066cb/lua/llm/config.lua#L10-L134

> You can switch between session histories by pressing `<C-j>/<C-k>` in the input box ((works in both Insert and Normal modes).

### Example Configuration

For example, the following configuration can do:

- Adjust the position of `popwin`.

- Set icons and prompt.

- Remap keys.
```lua
{
  "StubbornVegeta/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  branch = "save-sess",
  cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
  config = function()
    require("llm").setup({
      prompt = "Please answer in English!",
      max_tokens = 512,
      model = "@cf/qwen/qwen1.5-14b-chat-awq",
      prefix = {
        user = { text = "😃 ", hl = "Title" },
        assistant = { text = "⚡ ", hl = "Added" },
      },
      input_box_opts = {
        relative = "editor",
        position = {
          row = "85%",
          col = 15,
        },
        size = {
          height = "5%",
          width = 120,
        },
        enter = true,
        focusable = true,
        zindex = 50,
        border = {
          style = "rounded",
          text = {
            top = " Enter Your Question ",
            top_align = "center",
          },
        },
        win_options = {
          winblend = 0,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
      output_box_opts = {
        style = "float", -- right | left | above | below | float
        relative = "editor",
        position = {
          row = "35%",
          col = 15,
        },
        size = {
          height = "65%",
          width = 90,
        },
        enter = true,
        focusable = true,
        zindex = 20,
        border = {
          style = "rounded",
          text = {
            top = " LLM ",
            top_align = "center",
          },
        },
      },

      history_box_opts = {
        relative = "editor",
        position = {
          row = "35%",
          col = 108,
        },
        size = {
          height = "65%",
          width = 27,
        },
        zindex = 70,
        focusable = false,
        border = {
          style = "rounded",
          text = {
            top = " History ",
            top_align = "center",
          },
        },
        win_options = {
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
      popwin_opts = {
        relative = "cursor",
        position = {
          row = -7,
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
    { "<leader>ae", mode = "v", "<cmd>LLMSelectedTextHandler 请解释下面这段代码<cr>" },
    { "<leader>t", mode = "x", "<cmd>LLMSelectedTextHandler 英译汉<cr>" },
  },
},
```
