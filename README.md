<p align="center">
  <img src="https://github.com/Kurama622/screenshot/raw/master/llm/llm-logo-light-purple-font.png" alt="llm.nvim" width="345">
</p>
<p align="center">
  <a href="README.md"><b>English</b></a> |
  <a href="README_CN.md">简体中文</a>
</p>

---

> [!IMPORTANT]
> A free large language model(LLM) plugin that allows you to interact with LLM in Neovim.
>
> 1. Supports any LLM, such as GPT, GLM, Kimi, deepseek or local LLMs (such as ollama).
> 2. Allows you to define your own AI tools, with different tools able to use different models.
> 3. Most importantly, you can use free models provided by any platform (such as `Cloudflare`, `GitHub models`, `SiliconFlow`, `openrouter` or other platforms).


# Contents
<!-- mtoc-start -->

* [Screenshots](#screenshots)
  * [Chat](#chat)
  * [Quick Translation](#quick-translation)
  * [Explain Code](#explain-code)
  * [Optimize Code](#optimize-code)
  * [Generate Test Cases](#generate-test-cases)
  * [AI Translation](#ai-translation)
  * [Generate Git Commit Message](#generate-git-commit-message)
  * [Generate Doc String](#generate-doc-string)
* [Installation](#installation)
  * [Dependencies](#dependencies)
  * [Preconditions](#preconditions)
    * [Cloudflare](#cloudflare)
    * [ChatGLM (智谱清言)](#chatglm-智谱清言)
    * [kimi (月之暗面)](#kimi-月之暗面)
    * [Github Models](#github-models)
    * [siliconflow (硅基流动)](#siliconflow-硅基流动)
    * [Deepseek](#deepseek)
    * [openrouter](#openrouter)
    * [Local LLM](#local-llm)
  * [Basic Configuration](#basic-configuration)
  * [Window Style Configuration](#window-style-configuration)
  * [Configuration of AI Tools](#configuration-of-ai-tools)
  * [Local LLM Configuration](#local-llm-configuration)
* [Default Shortcuts](#default-shortcuts)
* [Author's configuration](#authors-configuration)
* [Q&A](#qa)
  * [The format of curl usage in Windows is different from Linux, and the default request format of llm.nvim may cause issues under Windows.](#the-format-of-curl-usage-in-windows-is-different-from-linux-and-the-default-request-format-of-llmnvim-may-cause-issues-under-windows)
  * [Switching between multiple LLMs and frequently changing the value of LLM_KEY is troublesome, and I don't want to expose my key in Neovim's configuration file.](#switching-between-multiple-llms-and-frequently-changing-the-value-of-llm_key-is-troublesome-and-i-dont-want-to-expose-my-key-in-neovims-configuration-file)
  * [Priority of different parse/streaming functions](#priority-of-different-parsestreaming-functions)
  * [How can the AI-generated git commit message feature be integrated with lazygit](#how-can-the-ai-generated-git-commit-message-feature-be-integrated-with-lazygit)

<!-- mtoc-end -->

## Screenshots

### Chat
<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" width="560">
</p>

### Quick Translation
<p align= "center">
  <img src="https://github.com/user-attachments/assets/4c98484a-f0af-45ae-9b62-ea0069ccbf60" alt="llm-translate" width="560">
</p>

### Explain Code
<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="560">
</p>

### Optimize Code
  - **Display side by side**
  <p align= "center">
    <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="560">
  </p>

  - **Display in the form of a diff**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/35c105b3-a2a9-4a6c-887c-cb20b77b3264" alt="llm-optimize-compare-action" width="560">
  </p>

### Generate Test Cases
<p align= "center">
  <img src="https://github.com/user-attachments/assets/b288e3c9-7d25-40cb-8645-14dacb571529" alt="test-case" width="560">
</p>

### AI Translation
<p align= "center">
  <img src="https://github.com/user-attachments/assets/ff90b1b4-3c2c-40e6-9321-4bab134710ec" alt="llm-trans" width="560">
</p>

### Generate Git Commit Message
<p align= "center">
  <img src="https://github.com/user-attachments/assets/261b21c5-0df0-48c2-916b-07f5ce0c981d" alt="llm-git-commit-msg" width="560">
</p>

### Generate Doc String
<p align= "center">
  <img src="https://github.com/user-attachments/assets/a1ae0ba7-d914-4bcd-a136-b88d79f7eb91" alt="llm-docstring" width="560">
</p>

[⬆ back to top](#contents)

## Installation

### Dependencies

- `curl`

### Preconditions

#### Cloudflare

1. Register [cloudflare](https://dash.cloudflare.com/), obtain an account and API Key. You can see all of Cloudflare's models [here](https://developers.cloudflare.com/workers-ai/models/), with the ones marked as beta being free models.

2. Set the `ACCOUNT` and `LLM_KEY` environment variables in your `zshrc` or `bashrc`.

```bash
export ACCOUNT=<Your ACCOUNT>
export LLM_KEY=<Your API_KEY>
```
#### ChatGLM (智谱清言)

1. Register ZhiPu QingYan: [https://open.bigmodel.cn/](https://open.bigmodel.cn/), obtain your API Key.

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Your API_KEY>
```

#### kimi (月之暗面)
1. Register Moonshot AI: [Moonshot AI 开放平台](https://login.moonshot.cn/?source=https%3A%2F%2Fplatform.moonshot.cn%2Fredirect&appid=dev-workbench), obtain your API Key.

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Your API_KEY>
```

#### Github Models
1. Obtain your [Github Token](https://github.com/settings/tokens)

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Github Token>
```

#### siliconflow (硅基流动)
1. Register for Siliconflow: [siliconflow](https://account.siliconflow.cn/login?redirect=https%3A%2F%2Fcloud.siliconflow.cn%2F%3F), obtain your API Key. You can see all models on Siliconflow [here](https://cloud.siliconflow.cn/models), and select 'Only Free' to see all free models.

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Your API_KEY>
```

#### Deepseek
1. Register for Deepseek: [deepseek](https://platform.deepseek.com/api_keys), obtain your API Key.

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Your API_KEY>
```

#### openrouter
1. Register openrouter: [openrouter](https://openrouter.ai/), obtain your API Key.

2. Set the `LLM_KEY` environment variable in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=<Your API_KEY>
```


#### Local LLM
Set `LLM_KEY` to `NONE` in your `zshrc` or `bashrc`.
```bash
export LLM_KEY=NONE
```

[⬆ back to top](#contents)


### Basic Configuration

**Some commands you should know about**

- `LLMSessionToggle`: open/hide the Chat UI.
- `LLMSelectedTextHandler`: Handles the selected text, the way it is processed depends on the prompt words you input.
- `LLMAppHandler`: call AI tools.

> If the URL is not configured, the default is to use Cloudflare.

```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        prompt = "You are a helpful chinese assistant.",

        prefix = {
          user = { text = "😃 ", hl = "Title" },
          assistant = { text = "⚡ ", hl = "Added" },
        },

        style = "float", -- right | left | above | below | float

        -- [[ Github Models ]]
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o",
        api_type = "openai",
        --[[ Optional: If you need to use models from different platforms simultaneously,
        you can configure the `fetch_key` to ensure that different models use different API Keys.]]
        fetch_key = function()
          return switch("enable_gpt")
        end,

        -- [[ cloudflare ]]
        -- model = "@cf/google/gemma-7b-it-lora",

        -- [[ ChatGLM ]]
        -- url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        -- model = "glm-4-flash",

        -- [[ kimi ]]
        -- url = "https://api.moonshot.cn/v1/chat/completions",
        -- model = "moonshot-v1-8k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
        -- api_type = "openai",

        -- [[ ollama ]]
        -- url = "http://localhost:11434/api/chat",
        -- model = "llama3.2:1b",
        -- api_type = "ollama",

        -- [[ siliconflow ]]
        -- url = "https://api.siliconflow.cn/v1/chat/completions",
        -- api_type = "openai",
        -- model = "Qwen/Qwen2.5-7B-Instruct",
        -- -- [optional: fetch_key]
        -- fetch_key = function()
        --   return switch("enable_siliconflow")
        -- end,

        -- [[ openrouter ]]
        -- url = "https://openrouter.ai/api/v1/chat/completions",
        -- model = "google/gemini-2.0-flash-exp:free",
        -- api_type = "openai",
        -- fetch_key = function()
        --   return switch("enable_openrouter")
        -- end,

        -- [[deepseek]]
        -- url = "https://api.deepseek.com/chat/completions",
        -- model = "deepseek-chat",
        -- api_type = "openai",
        -- fetch_key = function()
        --   return switch("enable_deepseek")
        -- end,

        max_tokens = 1024,
        save_session = true,
        max_history = 15,
        history_path = "/tmp/history",    -- where to save history
        temperature = 0.3,
        top_p = 0.7,

        spinner = {
          text = {
            "󰧞󰧞",
            "󰧞󰧞",
            "󰧞󰧞",
            "󰧞󰧞",
          },
          hl = "Title",
        },

        display = {
          diff = {
            layout = "vertical", -- vertical|horizontal split for default provider
            opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
            provider = "mini_diff", -- default|mini_diff
          },
        },

        -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Cancel"]      = { mode = "n", key = "<C-c>" },
          ["Input:Submit"]      = { mode = "n", key = "<cr>" },
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

- `prompt`: Model prompt.
- `prefix`: Dialog role indicator.
- `style`: Style of the Chat UI (float means floating window, others are split windows).
- `url`: Model api url.
- `model`: Model name.
- `api_type`: The parsing format of the model output: `openai`, `zhipu`, `ollama`, `workers-ai`. The `openai` format is compatible with most models, but `ChatGLM` can only be parsed using the `zhipu` format, and `cloudflare` can only be parsed using the `workers-ai` format. If you use ollama to run the model, you can use `ollama`.
- `fetch_key`: If you need to use models from different platforms simultaneously, you can configure `fetch_key` to ensure that different models use different API Keys. The usage is as follows:
  ```lua
  fetch_key = function() return "<your api key>" end
  ```
- `max_tokens`: Maximum output length of the model.
- `save_session`: Whether to save session history.
- `max_history`: Maximum number of saved sessions.
- `history_path`: Path for saving session history.
- `temperature`: The temperature of the model, controlling the randomness of the model's output.
- `temperature`: The top_p of the model, controlling the randomness of the model's output.
- `spinner`: The waiting animation of the model output (effective when non-streaming output).
- `display`
  - `diff`: Display style of diff (effective when optimizing code and showing diff, the style in the screenshot is mini_diff, which requires installation of [mini.diff](https://github.com/echasnovski/mini.diff)).

- `keys`: Shortcut key settings for different windows, default values can be found in [Default Shortcuts](#default-shortcuts)
  - *floating style*
    - input window
      - `Input:Cancel`: Cancel dialog response.
      - `Input:Submit`: Submit your question.
      - `Input:Resend`: Rerespond to the dialog.
      - `Input:HistoryNext`: Select the next session history.
      - `Input:HistoryPrev`: Select the previous session history.
    - Chat UI
      - `Session:Toggle`: open/hide the Chat UI.
      - `Session:Close`: close the Chat UI.
  - *split style*
    - output window
      - `Output:Ask`: Open input window.
      - `Output:Cancel`: Cancel diaglog response.
      - `Output:Resend`: Rerespond to the dialog.

If you use a local LLM (but not one running on ollama), you may need to define the streaming_handler (required), as well as the parse_handler (optional, used by only a few AI tools), for details see [Local LLM Configuration](#local-llm-configuration).

[⬆ back to top](#contents)

### Window Style Configuration

If you want to further configure the style of the conversation interface, you can configure `chat_ui_opts` and `popwin_opts` separately.
 
Their configuration options are the same:
- `relative`:
  - `editor`: The floating window relative to the current editor window.
  - `cursor`: The floating window relative to the current cursor position.
  - `win`: The floating window relative to the current window.

- `position`: The position of the window.
- `size`: The size of the window.
- `enter`: Whether the window automatically gains focus.
- `focusable`: Whether the window can gain focus.
- `zindex`: The layer of the window.
- `border`
  - `style`: The style of the window border.
  - `text`: The text of the window border.
- `win_options`: The options of the window.
  - `winblend`: The transparency of the window.
  - `winhighlight`: The highlight of the window.

More information can be found in [nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md).

Example: [UI](examples/ui)

[⬆ back to top](#contents)

### Configuration of AI Tools

Currently, llm.nvim provides some templates for AI tools, making it convenient for everyone to customize their own AI tools.

All AI tools need to be defined in `app_handler`, presented in the form of a pair of `key-value` (`key` is the tool name and `value` is the configuration information of the tool).

For all AI tools, their configuration options are similar:

- `handler`: Which template to use
  - `side_by_side_handler`: Display results in two windows side by side
  - `action_handler`: Display results in the source file in the form of a diff
    - `Y`/`y`: Accept LLM suggested code
    - `N`/`n`: Reject LLM suggested code
    - `<ESC>`: Exit directly
    - `I`/`i`: Input additional optimization conditions
    - `<C-r>`: Optimize again directly
  - `qa_handler`: AI for single-round dialogue
  - `flexi_handler`: Results will be displayed in a flexible window (window size is automatically calculated based on the amount of output text)
  - You can also customize functions
- `prompt`: Prompt words for the AI tool
- `opts`
  - `spell`: Whether to have spell check
  - `number`: Whether to display line numbers
  - `wrap`: Whether to automatically wrap lines
  - `linebreak`: Whether to allow line breaks in the middle of words
  - `url`, `model`: The LLM used by this AI tool
  - `api_type`: The type of parsing output by this AI tool
  - `streaming_handler`: This AI tool uses a custom streaming parsing function
  - `parse_handler`: This AI tool uses a custom parsing function
  - `border`: Floating window border style
  - `accept`
    - `mapping`: The key mapping for accepting the output
      - `mode`: Vim mode (Default mode: `n`)
      - `keys`: Your key mappings. (Default keys: `Y`/`y`)
    - `action`: The action for accepting the output, which is executed when accepting the output. (Default action: Copy the output)
  - `reject`
    - `mapping`: The key mapping for rejecting the output
      - `mode`: Vim mode (Default mode: `n`)
      - `keys`: Your key mappings. (Default keys: `N`/`n`)
    - `action`: The action for rejecting the output, which is executed when rejecting the output. (Default action: None or close the window)
  - `close`
    - `mapping`: The key mapping for closing the AI tool
      - `mode`: Vim mode (Default mode: `n`)
      - `keys`: Your key mappings. (Default keys: `<ESC>`)
    - `action`: The action for closing the AI tool. (Default action: Reject all output and close the window)

Different templates also have some exclusive configuration items of their own.

- You can also define in the `opts` of `qa_handler`:
  - `component_width`: the width of the component
  - `component_height`: the height of the component
  - `query`
      - `title`: the title of the component, which will be displayed in the center above the component
      - `hl`: the highlight of the title
  - `input_box_opts`: the window options for the input box (`size`, `win_options`)
  - `preview_box_opts`: the window options for the preview box (`size`, `win_options`)

- You can also define in the `opts` of `action_handler`:
  - `language`: The language used for the output result (`English`/`Chinese`/`Japanese` etc.)
  - `input`
    - `relative`: The relative position of the split window (`editor`/`win`)
    - `position`: The position of the split window (`top`/`left`/`right`/`bottom`)
    - `size`: The proportion of the split window (default is 25%)
    - `enter`: Whether to automatically enter the window
  - `output`
    - `relative`: Same as `input`
    - `position`: Same as `input`
    - `size`: Same as `input`
    - `enter`: Same as `input`

- In the `opts` of `side_by_side_handler`, you can also define:
  - `left` Left window
    - `title`: The title of the window
    - `focusable`: Whether the window can gain focus
    - `border`
    - `win_options`
  - `right` Right window
    - `title`: The title of the window
    - `focusable`: Whether the window can gain focus
    - `border`
    - `win_options`

- In the `opts` of `flexi_handler`, you can also define:
  - `exit_on_move`: Whether to close the flexible window when the cursor moves
  - `enter_flexible_window`: Whether to automatically enter the window when the flexible window pops up
  - `apply_visual_selection`: Whether to append the selected text content after the `prompt`

My some AI tool configurations:
~~~lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      local tools = require("llm.common.tools")
      require("llm").setup({
        app_handler = {
          OptimizeCode = {
            handler = tools.side_by_side_handler,
            -- opts = {
            --   streaming_handler = local_llm_streaming_handler,
            -- },
          },
          TestCode = {
            handler = tools.side_by_side_handler,
            prompt = [[ Write some test cases for the following code, only return the test cases.
            Give the code content directly, do not use code blocks or other tags to wrap it. ]],
            opts = {
              right = {
                title = " Test Cases ",
              },
            },
          },
          OptimCompare = {
            handler = tools.action_handler,
            opts = {
              fetch_key = function()
                return switch("enable_gpt")
              end,
              url = "https://models.inference.ai.azure.com/chat/completions",
              model = "gpt-4o",
              api_type = "openai",
            },
          },

          Translate = {
            handler = tools.qa_handler,
            opts = {
              fetch_key = function()
                return switch("enable_glm")
              end,
              url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
              model = "glm-4-flash",
              api_type = "zhipu",

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
            },
          },

          -- check siliconflow's balance
          UserInfo = {
            handler = function()
              local key = os.getenv("LLM_KEY")
              local res = tools.curl_request_handler(
                "https://api.siliconflow.cn/v1/user/info",
                { "GET", "-H", string.format("'Authorization: Bearer %s'", key) }
              )
              if res ~= nil then
                print("balance: " .. res.data.balance)
              end
            end,
          },
          WordTranslate = {
            handler = tools.flexi_handler,
            prompt = "Translate the following text to Chinese, please only return the translation",
            opts = {
              fetch_key = function()
                return switch("enable_glm")
              end,
              url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
              model = "glm-4-flash",
              api_type = "zhipu",
              args = [[return {url, "-N", "-X", "POST", "-H", "Content-Type: application/json", "-H", authorization, "-d", vim.fn.json_encode(body)}]],
              exit_on_move = true,
              enter_flexible_window = false,
            },
          },
          CodeExplain = {
            handler = tools.flexi_handler,
            prompt = "Explain the following code, please only return the explanation, and answer in Chinese",
            opts = {
              fetch_key = function()
                return switch("enable_glm")
              end,
              url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
              model = "glm-4-flash",
              api_type = "zhipu",
              enter_flexible_window = true,
            },
          },
          CommitMsg = {
            handler = tools.flexi_handler,
            prompt = function()
              return string.format(
                [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:
1. Start with an action verb (e.g., feat, fix, refactor, chore, etc.), followed by a colon.
2. Briefly mention the file or module name that was changed.
3. Describe the specific changes made.

Examples:
- feat: update common/util.py, added test cases for util.py
- fix: resolve bug in user/auth.py related to login validation
- refactor: optimize database queries in models/query.py

Based on this format, generate appropriate commit messages. Respond with message only. DO NOT format the message in Markdown code blocks, DO NOT use backticks:

```diff
%s
```
]],
                vim.fn.system("git diff --no-ext-diff --staged")
              )
            end,
            opts = {
              fetch_key = function()
                return switch("enable_glm")
              end,
              url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
              model = "glm-4-flash",
              api_type = "zhipu",
              enter_flexible_window = true,
              apply_visual_selection = false,
            },
          },
        },
    })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ts", mode = "x", "<cmd>LLMAppHandler WordTranslate<cr>" },
      { "<leader>ae", mode = "v", "<cmd>LLMAppHandler CodeExplain<cr>" },
      { "<leader>at", mode = "n", "<cmd>LLMAppHandler Translate<cr>" },
      { "<leader>tc", mode = "x", "<cmd>LLMAppHandler TestCode<cr>" },
      { "<leader>ao", mode = "x", "<cmd>LLMAppHandler OptimCompare<cr>" },
      { "<leader>au", mode = "n", "<cmd>LLMAppHandler UserInfo<cr>" },
      { "<leader>ag", mode = "n", "<cmd>LLMAppHandler CommitMsg<cr>" },
      -- { "<leader>ao", mode = "x", "<cmd>LLMAppHandler OptimizeCode<cr>" },
    },
  },
~~~

[⬆ back to top](#contents)

### Local LLM Configuration

Local LLMs require custom parsing functions; for streaming output, we use our custom `streaming_handler`; for AI tools that return output results in one go, we use our custom `parse_handler`.
 
Below is an example of `ollama` running `llama3.2:1b`.
```lua
local function local_llm_streaming_handler(chunk, line, assistant_output, bufnr, winid, F)
  if not chunk then
    return assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    line = line .. chunk
  else
    line = line .. chunk
    local status, data = pcall(vim.fn.json_decode, line)
    if not status or not data.message.content then
      return assistant_output
    end
    assistant_output = assistant_output .. data.message.content
    F.WriteContent(bufnr, winid, data.message.content)
    line = ""
  end
  return assistant_output
end

local function local_llm_parse_handler(chunk)
  local assistant_output = chunk.message.content
  return assistant_output
end

return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        url = "http://localhost:11434/api/chat", -- your url
        model = "llama3.2:1b",

        streaming_handler = local_llm_streaming_handler,
        app_handler = {
          WordTranslate = {
            handler = tools.flexi_handler,
            prompt = "Translate the following text to Chinese, please only return the translation",
            opts = {
              parse_handler = local_llm_parse_handler,
              exit_on_move = true,
              enter_flexible_window = false,
            },
          },
        }
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  }
}
```

[⬆ back to top](#contents)

## Default Shortcuts

- floating window

| window       | key          | mode     | desc                                |
| ------------ | ------------ | -------- | -----------------------             |
| Input        | `ctrl+g`     | `i`      | Submit your question                |
| Input        | `ctrl+c`     | `i`      | Cancel dialog response              |
| Input        | `ctrl+r`     | `i`      | Rerespond to the dialog             |
| Input        | `ctrl+j`     | `i`      | Select the next session history     |
| Input        | `ctrl+k`     | `i`      | Select the previous session history |
| Output+Input | `<leader>ac` | `n`      | Toggle session                      |
| Output+Input | `<esc>`      | `n`      | Close session                       |

- split window

| window       | key          | mode     | desc                    |
| ------------ | ------------ | -------- | ----------------------- |
| Input        | `<cr>`       | `n`      | Submit your question    |
| Output       | `i`          | `n`      | Open the input box      |
| Output       | `ctrl+c`     | `n`      | Cancel dialog response  |
| Output       | `ctrl+r`     | `n`      | Rerespond to the dialog |

[⬆ back to top](#contents)

## Author's configuration

[plugins/llm](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/llm)

---

## Q&A

### The format of curl usage in Windows is different from Linux, and the default request format of llm.nvim may cause issues under Windows.

Use a custom request format

- Basic Chat and some AI tools (using streaming output) with customized request format

  Define the `args` parameter at the same level as the `prompt`.
  ```lua
  --[[ custom request args ]]
  args = [[return {url, "-N", "-X", "POST", "-H", "Content-Type: application/json", "-H", authorization, "-d", vim.fn.json_encode(body)}]],
  ```

- AI tools (using non-streaming output) custom request format

  Define args in `opts`
  ```lua
    WordTranslate = {
      handler = tools.flexi_handler,
      prompt = "Translate the following text to Chinese, please only return the translation",
      opts = {
        fetch_key = function()
          return switch("enable_glm")
        end,
        url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        model = "glm-4-flash",
        api_type = "zhipu",
        args = [[return {url, "-N", "-X", "POST", "-H", "Content-Type: application/json", "-H", authorization, "-d", vim.fn.json_encode(body)}]],
        exit_on_move = true,
        enter_flexible_window = false,
      },
    },
  ```

> [!NOTE]
> You need to modify the args according to your actual situation.

[⬆ back to top](#contents)

### Switching between multiple LLMs and frequently changing the value of LLM_KEY is troublesome, and I don't want to expose my key in Neovim's configuration file.

- Create a `.env` file specifically to store your various keys. Note: Do not upload this file to GitHub.

- Load the `.env` file in `zshrc` or `bashrc` and define some functions to switch between different LLMs.
  ```bash
  source ~/.config/zsh/.env

  export ACCOUNT=$WORKERS_AI_ACCOUNT
  export LLM_KEY=$SILICONFLOW_TOKEN

  enable_workers_ai() {
    export LLM_KEY=$WORKERS_AI_KEY
  }

  enable_glm() {
    export LLM_KEY=$GLM_KEY
  }

  enable_kimi() {
    export LLM_KEY=$KIMI_KEY
  }

  enable_gpt() {
    export LLM_KEY=$GITHUB_TOKEN
  }

  enable_siliconflow() {
    export LLM_KEY=$SILICONFLOW_TOKEN
  }
  enable_openai() {
    export LLM_KEY=$OPENAI_KEY
  }
  enable_local() {
    export LLM_KEY=$LOCAL_LLM_KEY
  }
  ```

- Finally, add the `switch` function in the llm.nvim configuration file.
  ```lua
  local function switch(shell_func)
    -- [LINK] https://github.com/Kurama622/dotfiles/blob/main/zsh/module/func.zsh
    local p = io.popen(string.format("source ~/.config/zsh/module/func.zsh; %s; echo $LLM_KEY", shell_func))
    local key = p:read()
    p:close()
    return key
  end
  ```
  Switching keys is completed through `fetch_key`.
  ```lua
    fetch_key = function()
      return switch("enable_glm")
    end,
  ```

[⬆ back to top](#contents)

### Priority of different parse/streaming functions

  AI tool configuration's `streaming_handler` or `parse_handler` > AI tool configuration's `api_type` > Main configuration's `streaming_handler` or `parse_handler` > Main configuration's `api_type`

[⬆ back to top](#contents)

### How can the AI-generated git commit message feature be integrated with lazygit
  ```lua
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("t", "<C-c>", function()
        vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
        vim.api.nvim_command("LLMAppHandler CommitMsg")
      end, { desc = "AI Commit Msg" })
    end,
  }
  ```
[⬆ back to top](#contents)
