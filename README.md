<p align= "center">
<img src="https://github.com/Kurama622/screenshot/raw/master/llm/llm-logo-light-purple.png" alt="llm.nvim" width="345">
</p>

---

> [!IMPORTANT]
> This is a universal plugin for a large language model (LLM), designed to enable users to interact with LLM within neovim.
>
> You can customize any LLM (such as glm, kimi) you wish to use.
>
> You can customize some useful tools to complete your tasks more effectively.
>
> Finally, and most importantly, you can use various free models (whether provided by Cloudflare or others).

## Screenshots

### Chat

You can converse with it just like you would with ChatGPT.

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" width="450">
</p>

### Quick Translate

Select the text to translate quickly.

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-translate-compress.png" alt="llm-translate" width="450">
</p>

### Explain Code

Can't understand the code? Don't worry, AI will explain every code snippet for you.

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="450">
</p>

### Customizable LLM application tools

You can customize some useful tools to complete your tasks more effectively. Detailed tutorial can be found on [wiki](https://github.com/Kurama622/llm.nvim/wiki/app-tools#how-to-add-an-application-tool-to-llmnvim).


#### Optimize Code

Let AI optimize your code. [wiki: create-a-tool-to-help-optimize-your-code](https://github.com/Kurama622/llm.nvim/wiki/app-tools#create-a-tool-to-help-optimize-your-code)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="450">
</p>

#### Translate

Your next translator is not a translator. [wiki: create-a-translator-tool](https://github.com/Kurama622/llm.nvim/wiki/app-tools#create-a-translator-tool)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-trans-compress.png" alt="llm-trans" width="450">
</p>

## Installation

### cloudflare

1. You need sign up on [cloudflare](https://dash.cloudflare.com/) and get your account and API key. Then you will find all [models](https://developers.cloudflare.com/workers-ai/models/) on cloudflare, where the models labeled as beta are free.

2. Set `ACCOUNT` and `LLM_KEY` in your zshrc or bashrc
```sh
export ACCOUNT=<Your ACCOUNT>
export LLM_KEY=<Your API_KEY>
```

- lazy.nvim

```lua
  {
    "Kurama622/llm.nvim",
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

### ChatGLM (智谱清言)

1. You need sign up on [https://open.bigmodel.cn/](https://open.bigmodel.cn/), and get your account and API key.

2. `LLM_KEY` in your zshrc or bashrc

```bash
export LLM_KEY=<Your API_KEY>
```

- lazy.nvim
```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        max_tokens = 512,
        url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        model = "glm-4-flash",
        prefix = {
          user = { text = "😃 ", hl = "Title" },
          assistant = { text = "⚡ ", hl = "Added" },
        },

        save_session = true,
        max_history = 15,

        -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Submit"]      = { mode = "n", key = "<cr>" },
          ["Input:Cancel"]      = { mode = "n", key = "<C-c>" },
          ["Input:Resend"]      = { mode = "n", key = "<C-r>" },

          -- only works when "save_session = true"
          ["Input:HistoryNext"] = { mode = "n", key = "<C-j>" },
          ["Input:HistoryPrev"] = { mode = "n", key = "<C-k>" },

          -- The keyboard mapping for the output window in "split" style.
          ["Output:Ask"]        = { mode = "n", key = "i" },
          ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
          ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output and input windows in "float" style.
          ["Session:Toggle"]    = { mode = "n", key = "<leader>ac" },
          ["Session:Close"]     = { mode = "n", key = "<esc>" },
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

### Customized Large Language Model

1. Add the requested URL.
2. Specify the model you will be using.
3. Customize the streaming processing function (used for parsing the model output).

- lazy.nvim
```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        max_tokens = 4095,
        url = "https://api.moonshot.cn/v1/chat/completions",
        model = "moonshot-v1-128k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"

        streaming_handler = function(chunk, line, output, bufnr, winid, F)
          if not chunk then
            return output
          end
          local tail = chunk:sub(-1, -1)
          if tail:sub(1, 1) ~= "}" then
            line = line .. chunk
          else
            line = line .. chunk

            local start_idx = line:find("data: ", 1, true)
            local end_idx = line:find("}]", 1, true)
            local json_str = nil

            while start_idx ~= nil and end_idx ~= nil do
              if start_idx < end_idx then
                json_str = line:sub(7, end_idx + 1) .. "}"
              end
              local data = vim.fn.json_decode(json_str)
              if not data.choices[1].delta.content then
                break
              end

              output = output .. data.choices[1].delta.content
              F.WriteContent(bufnr, winid, data.choices[1].delta.content)

              if end_idx + 2 > #line then
                line = ""
                break
              else
                line = line:sub(end_idx + 2)
              end
              start_idx = line:find("data: ", 1, true)
              end_idx = line:find("}]", 1, true)
            end
          end
          return output
        end
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  }
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

https://github.com/Kurama622/llm.nvim/blob/51350dc2028249b2ac04ec3b0763dcaca18bd059/lua/llm/config.lua#L26-L166

### Example Configuration
```lua
  {
    "Kurama622/llm.nvim",
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

Finally, here is my personal configuration for reference.

https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/llm.lua
