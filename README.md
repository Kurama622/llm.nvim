# llm.nvim

Free large language model (LLM) support for Neovim based on [cloudflare](https://dash.cloudflare.com/).

You need sign up on [cloudflare](https://dash.cloudflare.com/) and get your account and API key. Then you will find all [models](https://developers.cloudflare.com/workers-ai/models/) on cloudflare, where the models labeled as beta are free.


## Screenshots

<p align= "center">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" height="280">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-translate-compress.png" alt="llm-translate" height="280">
  <img src="https://github.com/StubbornVegeta/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" height="250">
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
      require("llm").setup()
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ae", mode = "v", "<cmd>LLMSelectedTextHandler 请解释下面这段代码<cr>" },
      { "<leader>t", mode = "x", "<cmd>LLMSelectedTextHandler 英译汉<cr>" },
    },
  },
```

## Default Configuration

- floating window

| window       | key          | mode     | desc                                |
| ------------ | ------------ | -------- | -----------------------             |
| Input        | `ctrl+g`     | `i`      | submit your question                |
| Input        | `ctrl+c`     | `i`      | cancel dialog response              |
| Input        | `ctrl+r`     | `i`      | Rerespond to the dialog             |
| Input        | `ctrl+j`     | `i`      | select the next session history     |
| Input        | `ctrl+k`     | `i`      | select the previous session history |
| Output+Input | `<leader>ac` | `n`      | toggle session                      |
| Output+Input | `<esc>`      | `n`      | close session                       |

- split window

| window       | key          | mode     | desc                    |
| ------------ | ------------ | -------- | ----------------------- |
| Input        | `<cr>`       | `n`      | submit your question    |
| Output       | `i`          | `n`      | open the input box      |
| Output       | `ctrl+c`     | `n`      | cancel dialog response  |
| Output       | `ctrl+r`     | `n`      | Rerespond to the dialog |


## Configuration

`llm.nvim` comes with the following defaults, you can override them by passing config as setup param.

### Example Configuration

```lua
  {
    "StubbornVegeta/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        prompt = "请用中文回答",
        max_tokens = 512,
        model = "@cf/qwen/qwen1.5-14b-chat-awq",
        prefix = {
          user = { text = "😃 ", hl = "Title" },
          assistant = { text = "⚡ ", hl = "Added" },
        },

        save_session = true,              -- if false, history box will not be showed
        max_history = 15,                 -- max number of history
        history_path = "/tmp/history",    -- where to save history

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
            -- set window transparency
            winblend = 20,
            -- set window highlight
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
              top = " Preview ",
              top_align = "center",
            },
          },
          win_options = {
            winblend = 20,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
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
          enter = false,
          focusable = false,
          border = {
            style = "rounded",
            text = {
              top = " History ",
              top_align = "center",
            },
          },
          win_options = {
            winblend = 20,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },

        -- LLMSelectedTextHandler windows options
        popwin_opts = {
          relative = "cursor",
          position = {
            row = -7,
            col = 20,
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

          -- only works when "save_session = true"
          ["Input:HistoryNext"]  = { mode = "n", key = "<C-j>" },
          ["Input:HistoryPrev"]  = { mode = "n", key = "<C-k>" },

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
