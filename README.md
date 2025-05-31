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

> [!NOTE]
> The configurations of different LLMs (such as **ollama**, **deepseek**), UI configurations, and AI tools (including **code completion**) should be checked in the [examples](examples) first. Here you will find most of the information you want to know. Additionally, before using the plugin, you should ensure that your `LLM_KEY` is **valid** and that the environment variable is in effect.



# Contents
<!-- mtoc-start -->

* [Screenshots](#screenshots)
  * [Chat](#chat)
  * [Code Completions](#code-completions)
  * [Quick Translation](#quick-translation)
  * [Explain Code](#explain-code)
  * [Ask](#ask)
  * [Attach To Chat](#attach-to-chat)
  * [Optimize Code](#optimize-code)
  * [Generate Test Cases](#generate-test-cases)
  * [AI Translation](#ai-translation)
  * [Generate Git Commit Message](#generate-git-commit-message)
  * [Generate Doc String](#generate-doc-string)
* [Installation](#installation)
  * [Dependencies](#dependencies)
  * [Preconditions](#preconditions)
    * [Websites of different AI platforms](#websites-of-different-ai-platforms)
  * [Minimal installation example](#minimal-installation-example)
* [Configuration](#configuration)
  * [Model Parameters](#model-parameters)
  * [keymaps](#keymaps)
  * [Commands](#commands)
  * [UI](#ui)
  * [Configuration of AI Tools](#configuration-of-ai-tools)
    * [Examples](#examples)
  * [Local LLM Configuration](#local-llm-configuration)
* [TODO List](#todo-list)
* [Author's configuration](#authors-configuration)
* [Acknowledgments](#acknowledgments)
  * [Special thanks](#special-thanks)
* [Q&A](#qa)
  * [The format of curl usage in Windows is different from Linux, and the default request format of llm.nvim may cause issues under Windows.](#the-format-of-curl-usage-in-windows-is-different-from-linux-and-the-default-request-format-of-llmnvim-may-cause-issues-under-windows)

<!-- mtoc-end -->

## Screenshots

### Chat

[models](./examples/chat/) | [UI](./examples/ui/)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" width="560">
</p>

### [Code Completions](./examples/ai-tools/Code-Completions/)
  - **virtual text**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/9215ba1c-df62-4ca8-badb-cf4b62262c57" alt="completion-virtual-text" width="560">
  </p>

  - **blink.cmp or nvim-cmp**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/93ef3c02-799d-435e-81fa-c4bf7df936d9" alt="completion-blink-cmp" width="560">
  </p>

### [Quick Translation](./examples/ai-tools/Word-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/4c98484a-f0af-45ae-9b62-ea0069ccbf60" alt="llm-translate" width="560">
</p>

### Explain Code

[Streaming output](./examples/chat/deepseek/config.lua#L52) | [Non-streaming output](./examples/ai-tools/Code-Explain/config.lua)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="560">
</p>

### [Ask](./examples/ai-tools/Ask/config.lua)

> One-time, no history retained.

You can configure [inline_assistant](./examples/ai-tools/Ask/config.lua) to decide whether to display diffs (default: show by pressing 'd').

<p align= "center">
  <img src="https://github.com/user-attachments/assets/e3300e1f-dbd2-4978-bd60-ddf9106257cb" alt="llm-ask" width="560">
</p>

### [Attach To Chat](./examples/ai-tools/Attach-To-Chat/config.lua)

You can configure [inline_assistant](./examples/ai-tools/Attach-To-Chat/config.lua) to decide whether to display diffs (default: show by pressing 'd').

<p align= "center">
  <img src="https://github.com/user-attachments/assets/33ba7517-6cf1-4e52-b6b4-27e6a4fb1148" alt="llm-attach" width="560">
</p>

### Optimize Code
  - [**Display side by side**](./examples/ai-tools/Optimize-Code/config.lua)
  <p align= "center">
    <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="560">
  </p>

  - [**Display in the form of a diff**](./examples/ai-tools/Optimize-Code-and-Display-Diff/config.lua)
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/35c105b3-a2a9-4a6c-887c-cb20b77b3264" alt="llm-optimize-compare-action" width="560">
  </p>

### [Generate Test Cases](./examples/ai-tools/Generate-Test-Cases/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/b288e3c9-7d25-40cb-8645-14dacb571529" alt="test-case" width="560">
</p>

### [AI Translation](./examples/ai-tools/AI-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/ff90b1b4-3c2c-40e6-9321-4bab134710ec" alt="llm-trans" width="560">
</p>

### [Generate Git Commit Message](./examples/ai-tools/AI-Commit-Messages/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/261b21c5-0df0-48c2-916b-07f5ce0c981d" alt="llm-git-commit-msg" width="560">
</p>

### [Generate Doc String](./examples/ai-tools/Generate-Docstring/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/a1ae0ba7-d914-4bcd-a136-b88d79f7eb91" alt="llm-docstring" width="560">
</p>

[⬆ back to top](#contents)

## Installation

### Dependencies

- `curl`

### Preconditions

1. Register on the official website and obtain your API Key (Cloudflare needs to obtain an additional account).

2. Set the `LLM_KEY` (Cloudflare needs to set an additional `ACCOUNT`) environment variable in your `zshrc` or `bashrc`.

```bash
export LLM_KEY=<Your API_KEY>
export ACCOUNT=<Your ACCOUNT> # just for cloudflare
```

#### Websites of different AI platforms

| Platform               | Link to obtain api key                                                                                                      | Note                                                                                                                                                 |
| -----------            | ----------                                                                                                                  | -------                                                                                                                                              |
| Cloudflare             | [https://dash.cloudflare.com/](https://dash.cloudflare.com/)                                                                | You can see all of Cloudflare's models [here](https://developers.cloudflare.com/workers-ai/models/), with the ones marked as beta being free models. |
| ChatGLM(智谱清言)      | [https://open.bigmodel.cn/](https://open.bigmodel.cn/)                                                                      |                                                                                                                                                      |
| Kimi(月之暗面)        | [Moonshot AI 开放平台](https://login.moonshot.cn/?source=https%3A%2F%2Fplatform.moonshot.cn%2Fredirect&appid=dev-workbench) |                                                                                                                                                      |
| Github Models          | [Github Token](https://github.com/settings/tokens)                                                                          |                                                                                                                                                      |
| siliconflow (硅基流动) | [siliconflow](https://account.siliconflow.cn/login?redirect=https%3A%2F%2Fcloud.siliconflow.cn%2F%3F)                       | You can see all models on Siliconflow [here](https://cloud.siliconflow.cn/models), and select 'Only Free' to see all free models.                    |
| Deepseek               | [https://platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)                                            |                                                                                                                                                      |
| Openrouter             | [https://openrouter.ai/](https://openrouter.ai/)                                                                            |                                                                                                                                                      |
| Chatanywhere           | [https://api.chatanywhere.org/v1/oauth/free/render](https://api.chatanywhere.org/v1/oauth/free/render)                      | 200 free calls to GPT-4o-mini are available every day.                                                                                               |

**For local llms, Set `LLM_KEY` to `NONE` in your `zshrc` or `bashrc`.**


[⬆ back to top](#contents)

### Minimal installation example

- lazy.nvim

```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim"},
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      require("llm").setup({
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o-mini",
        api_type = "openai"
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  }
```

## Configuration


### Model Parameters

| Parameter          | Description                                                                                                                                                                                                | Value                                                                                                                                       |
| ------------------ | -------                                                                                                                                                                                                    | -                                                                                                                                           |
| url                | Model entpoint                                                                                                                                                                                             | String                                                                                                                                      |
| model              | Model name                                                                                                                                                                                                 | String                                                                                                                                      |
| api_type           | Result parsing format                                                                                                                                                                                      |  `workers-ai` \| `zhipu`\|<br>`openai`\| `ollama`                                                                                             |
| timeout            | The maximum timeout for a response (in seconds)                                                                                                                                                            | Number                                                                                                                                      |
| fetch_key          | Function that returns the API key                                                                                                                                                                          | Function                                                                                                                                    |
| max_tokens         | Limits the number of tokens generated in a response.                                                                                                                                                       | Number                                                                                                                                      |
| temperature        | From 0 to 1.<br>The lower the number is, the more deterministic the response will be.<br>The higher the number is the more creative the response will be, but moe likely to go off topic if it's too high        | Number                                                                                                                                      |
| top_p              | A threshold(From 0 to 1).<br>The higher the threshold is the more diverse and the less repetetive the response will be.<br>(But it could also lead to less likely tokens which also means: off-topic responses.) | Number                                                                                                                                      |
| enable_thinking    | Activate the model's deep thinking ability (The model itself needs to ensure this feature.)                                                                                                                | Boolean                                                                                                                                     |
| thinking_budget    | The maximum length of the thinking process only takes effect when enable_thinking is true.                                                                                                                 | Number                                                                                                                                      |
| schema             | Function-calling required function parameter description                                                                                                                                                   | Table                                                                                                                                       |
| functions_tbl      | Function dict required for Function-calling                                                                                                                                                                | Table                                                                                                                                       |
| keep_alive         | Maintain connection (usually for ollama)                                                                                                                                                                   | see [keep_alive/OLLAMA_KEEP_ALIVE](https://github.com/ollama/ollama/blob/c02db93243353855b983db2a1562a02b57e66db1/docs/faq.md?plain=1#L214) |
| streaming_handler  | Customize the parsing format of the streaming output                                                                                                                                                       | Function                                                                                                                                    |
| parse_handler      | Customize the parsing format for non-streaming output                                                                                                                                                      | Function                                                                                                                                    |

### keymaps

| Style       | Keyname           | Description                                                                                   | Default: `[mode] keymap` | Window                                       |
| -           | -                 | -                                                                                             | -                        | -                                            |
| float       | Input:Submit      | Submit your question                                                                          | `[i] ctrl+g`             | Input                                        |
| float       | Input:Cancel      | Cancel dialog response                                                                        | `[i] ctrl+c`             | Input                                        |
| float       | Input:Resend      | Rerespond to the dialog                                                                       | `[i] ctrl+r`             | Input                                        |
| float       | Input:HistoryNext | Select the next session history                                                               | `[i] ctrl+j`             | Input                                        |
| float       | Input:HistoryPrev | Select the previous session history                                                           | `[i] ctrl+k`             | Input                                        |
| float       | Input:ModelsNext  | Select the next model                                                                         | `[i] ctrl+shift+j`       | Input                                        |
| float       | Input:ModelsPrev  | Select the previous model                                                                     | `[i] ctrl+shift+k`       | Input                                        |
| split       | Output:Ask        | Open the input box (In the normal mode of the input box, press Enter to submit your question) | `[n] i`                  | Output                                       |
| split       | Output:Cancel     | Cancel dialog response                                                                        | `[n] ctrl+c`             | Output                                       |
| split       | Output:Resend     | Rerespond to the dialog                                                                       | `[n] ctrl+r`             | Output                                       |
| float/split | Session:Toggle    | Toggle session                                                                                | `[n] <leader>ac`         | Input+Output                               |
| float/split | Session:Close     | Close session                                                                                 | `[n] <esc>`              | `float`: Input+Output<br>`split`: Output   |
| float/split | Session:Models    | Open the model-list window                                                                    | `[n] ctrl+m`             | `float`: App input window<br>`split`: Output |
| split       | Session:History   | Open the history window<br>`j`: next<br>`k`: previous<br>`<cr>`: select<br>`<esc>`: close     | `[n] ctrl+h`             | Output                                       |
| float       | Focus:Input       | Jump from the output window to the input window                                               | -                        | Output                                       |
| float       | Focus:Output      | Jump from the input window to the output window                                               | -                        | Input                                        |
| float       | PageUp            | Output Window page up                                                                         | `[n/i] Ctrl+b`           | Output                                       |
| float       | PageDown          | Output window page down                                                                       | `[n/i] Ctrl+f`           | Output                                       |
| float       | HalfPageUp        | Output Window page up (half)                                                                  | `[n/i] Ctrl+u`           | Output                                       |
| float       | HalfPageDown      | Output window page down (half)                                                                | `[n/i] Ctrl+d`           | Output                                       |
| float       | JumpToTop         | Jump to the top (output window)                                                               | `[n] gg`                 | Output                                       |
| float       | JumpToBottom      | Jump to the bottom (output window)                                                            | `[n] G`                  | Output                                       |

### Commands

| Cmd                      | Description                                                                              |
| ---                      | -----                                                                                    |
| `LLMSessionToggle`       | open/hide the Chat UI                                                                    |
| `LLMSelectedTextHandler` | Handles the selected text, the way it is processed depends on the prompt words you input |
| `LLMAppHandler`          | call AI tools                                                                            |

### UI

See [UI Configuration](examples/ui/) and [nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md)

[⬆ back to top](#contents)

### Configuration of AI Tools

Currently, llm.nvim provides some templates for AI tools, making it convenient for everyone to customize their own AI tools.

All AI tools need to be defined in `app_handler`, presented in the form of a pair of `key-value` (`key` is the tool name and `value` is the configuration information of the tool).

#### Examples

For more details or examples, please refer to [AI Tools Configuration](examples/ai-tools/).

<details>
<summary><b><i>Click here to see how to configure AI tools</i></b></summary>
<br/>

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
                return vim.env.GITHUB_TOKEN
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
                return vim.env.GLM_KEY
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
                return vim.env.GLM_KEY
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
                return vim.env.GLM_KEY
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
              -- Source: https://andrewian.dev/blog/ai-git-commits
              return string.format([[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

1. First line: conventional commit format (type: concise description) (remember to use semantic types like feat, fix, docs, style, refactor, perf, test, chore, etc.)
2. Optional bullet points if more context helps:
   - Keep the second line blank
   - Keep them short and direct
   - Focus on what changed
   - Always be terse
   - Don't overly explain
   - Drop any fluffy or formal language

Return ONLY the commit message - no introduction, no explanation, no quotes around it.

Examples:
feat: add user auth system

- Add JWT tokens for API auth
- Handle token refresh for long sessions

fix: resolve memory leak in worker pool

- Clean up idle connections
- Add timeout for stale workers

Simple change example:
fix: typo in README.md

Very important: Do not respond with any of the examples. Your message must be based off the diff that is about to be provided, with a little bit of styling informed by the recent commits you're about to see.

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
                return vim.env.GLM_KEY
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

</details>

[⬆ back to top](#contents)

### Local LLM Configuration

Local LLMs require custom parsing functions; for streaming output, we use our custom `streaming_handler`; for AI tools that return output results in one go, we use our custom `parse_handler`.
 
Below is an example of `ollama` running `llama3.2:1b`.

<details>
<summary><b><i>Expand the code.</i></b></summary>
<br/>

```lua
local function local_llm_streaming_handler(chunk, ctx, F)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    local status, data = pcall(vim.fn.json_decode, ctx.line)
    if not status or not data.message.content then
      return ctx.assistant_output
    end
    ctx.assistant_output = ctx.assistant_output .. data.message.content
    F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    ctx.line = ""
  end
  return ctx.assistant_output
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

</details>

[⬆ back to top](#contents)

## TODO List

[todo-list](https://github.com/Kurama622/llm.nvim/issues/44)

[⬆ back to top](#contents)

## Author's configuration

[plugins/llm](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/llm)

## Acknowledgments

We would like to express our heartfelt gratitude to the contributors of the following open-source projects, whose code has provided invaluable inspiration and reference for the development of llm.nvim:

- [olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim): Diff style and prompt.
- [SmiteshP/nvim-navbuddy](https://github.com/SmiteshP/nvim-navbuddy): UI.
- [milanglacier/minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim): Code completions.

### Special thanks

[ACKNOWLEDGMENTS](./ACKNOWLEDGMENTS.md)


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
          return vim.env.GLM_KEY
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

