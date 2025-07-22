<p align="center">
  <img src="https://github.com/Kurama622/screenshot/raw/master/llm/llm-logo-light-purple-font.png" alt="llm.nvim" width="345">
</p>
<p align="center">
  <a href="README.md"><b>English</b></a> |
  <a href="README_CN.md">简体中文</a>
</p>

---

> [!IMPORTANT]
> A large language model(LLM) plugin that allows you to interact with LLM in Neovim.
>
> 1. Supports any LLM, such as GPT, GLM, Kimi, DeepSeek, Gemini, Qwen or local LLMs (such as ollama).
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
  * [Web Search](#web-search)
* [Installation](#installation)
  * [Dependencies](#dependencies)
  * [Preconditions](#preconditions)
    * [Websites of different AI platforms](#websites-of-different-ai-platforms)
  * [Minimal installation example](#minimal-installation-example)
* [Configuration](#configuration)
  * [Commands](#commands)
  * [Model Parameters](#model-parameters)
  * [keymaps](#keymaps)
  * [Tool](#tool)
  * [UI](#ui)
  * [Custom parsing function](#custom-parsing-function)
* [TODO List](#todo-list)
* [Author's configuration](#authors-configuration)
* [Acknowledgments](#acknowledgments)
  * [Special thanks](#special-thanks)

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

### [Web Search](./docs/cmds/README.md#web_search)

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

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

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

</details>

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

- Mini.deps

```lua
require("mini.deps").setup()
MiniDeps.add({
        source = "Kurama622/llm.nvim",
        depends = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
        cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
})

require("llm").setup({
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o-mini",
        api_type = "openai"
})
```

**[Configure template](./basic_template.lua)**


## Configuration

### Commands

| Cmd                      | Description                                                                              |
| ---                      | -----                                                                                    |
| `LLMSessionToggle`       | Open/hide the Chat UI                                                                    |
| `LLMSelectedTextHandler` | Handle the selected text, the way it is processed depends on the prompt words you input |
| `LLMAppHandler`          | Call AI tools                                                                            |

### Model Parameters

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

| Parameter          | Description                                                                                                                                                                                                      | Value                                                                                                                                       |
| ------------------ | -------                                                                                                                                                                                                          | -                                                                                                                                           |
| url                | Model entpoint                                                                                                                                                                                                   | String                                                                                                                                      |
| model              | Model name                                                                                                                                                                                                       | String                                                                                                                                      |
| api_type           | Result parsing format                                                                                                                                                                                            | `workers-ai` \| `zhipu`\|<br>`openai`\| `ollama`                                                                                            |
| timeout            | The maximum timeout for a response (in seconds)                                                                                                                                                                  | Number                                                                                                                                      |
| fetch_key          | API key string or Function that returns the API key                                                                                                                                                              | Function \| String                                                                                                                            |
| max_tokens         | Limits the number of tokens generated in a response.                                                                                                                                                             | Number                                                                                                                                      |
| temperature        | From 0 to 1.<br>The lower the number is, the more deterministic the response will be.<br>The higher the number is the more creative the response will be, but moe likely to go off topic if it's too high        | Number                                                                                                                                      |
| top_p              | A threshold(From 0 to 1).<br>The higher the threshold is the more diverse and the less repetetive the response will be.<br>(But it could also lead to less likely tokens which also means: off-topic responses.) | Number                                                                                                                                      |
| enable_thinking    | Activate the model's deep thinking ability (The model itself needs to ensure this feature.)                                                                                                                      | Boolean                                                                                                                                     |
| thinking_budget    | The maximum length of the thinking process only takes effect when enable_thinking is true.                                                                                                                       | Number                                                                                                                                      |
| schema             | Function-calling required function parameter description                                                                                                                                                         | Table                                                                                                                                       |
| functions_tbl      | Function dict required for Function-calling                                                                                                                                                                      | Table                                                                                                                                       |
| keep_alive         | Maintain connection (usually for ollama)                                                                                                                                                                         | see [keep_alive/OLLAMA_KEEP_ALIVE](https://github.com/ollama/ollama/blob/c02db93243353855b983db2a1562a02b57e66db1/docs/faq.md?plain=1#L214) |
| streaming_handler  | Customize the parsing format of the streaming output                                                                                                                                                             | Function                                                                                                                                    |
| parse_handler      | Customize the parsing format for non-streaming output                                                                                                                                                            | Function                                                                                                                                    |

</details>

### keymaps

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

| Style       | Keyname           | Description                                                                                     | Default: `[mode] keymap` | Window                                       |
| -           | -                 | -                                                                                               | -                        | -                                            |
| float       | Input:Submit      | Submit your question                                                                            | `[i] ctrl+g`             | Input                                        |
| float       | Input:Cancel      | Cancel dialog response                                                                          | `[i] ctrl+c`             | Input                                        |
| float       | Input:Resend      | Rerespond to the dialog                                                                         | `[i] ctrl+r`             | Input                                        |
| float       | Input:HistoryNext | Select the next session history                                                                 | `[i] ctrl+j`             | Input                                        |
| float       | Input:HistoryPrev | Select the previous session history                                                             | `[i] ctrl+k`             | Input                                        |
| float       | Input:ModelsNext  | Select the next model                                                                           | `[i] ctrl+shift+j`       | Input                                        |
| float       | Input:ModelsPrev  | Select the previous model                                                                       | `[i] ctrl+shift+k`       | Input                                        |
| split       | Output:Ask        | Open the input box<br>In the normal mode of the input box, press Enter to submit your question) | `[n] i`                  | Output                                       |
| split       | Output:Cancel     | Cancel dialog response                                                                          | `[n] ctrl+c`             | Output                                       |
| split       | Output:Resend     | Rerespond to the dialog                                                                         | `[n] ctrl+r`             | Output                                       |
| float/split | Session:Toggle    | Toggle session                                                                                  | `[n] <leader>ac`         | Input+Output                                 |
| float/split | Session:Close     | Close session                                                                                   | `[n] <esc>`              | `float`: Input+Output<br>`split`: Output     |
| float/split | Session:Models    | Open the model-list window                                                                      | `[n] ctrl+m`             | `float`: App input window<br>`split`: Output |
| split       | Session:History   | Open the history window<br>`j`: next<br>`k`: previous<br>`<cr>`: select<br>`<esc>`: close       | `[n] ctrl+h`             | Output                                       |
| float       | Focus:Input       | Jump from the output window to the input window                                                 | -                        | Output                                       |
| float       | Focus:Output      | Jump from the input window to the output window                                                 | -                        | Input                                        |
| float       | PageUp            | Output Window page up                                                                           | `[n/i] Ctrl+b`           | Input                                        |
| float       | PageDown          | Output window page down                                                                         | `[n/i] Ctrl+f`           | Input                                        |
| float       | HalfPageUp        | Output Window page up (half)                                                                    | `[n/i] Ctrl+u`           | Input                                        |
| float       | HalfPageDown      | Output window page down (half)                                                                  | `[n/i] Ctrl+d`           | Input                                        |
| float       | JumpToTop         | Jump to the top (output window)                                                                 | `[n] gg`                 | Input                                        |
| float       | JumpToBottom      | Jump to the bottom (output window)                                                              | `[n] G`                  | Input                                        |

</details>

### Tool

| Handler name           | Description                                                                                                                    |
| --                     | --                                                                                                                             |
| side_by_side_handler   | Display results in two windows side by side                                                                                    |
| action_handler         | Display results in the source file in the form of a diff                                                                       |
| qa_handler             | AI for single-round dialogue                                                                                                   |
| flexi_handler          | Results will be displayed in a flexible window (window size is automatically calculated based on the amount of output text)    |
| disposable_ask_handler | Flexible questioning, you can choose a piece of code to ask about, or you can ask directly (the current buffer is the context) |
| attach_to_chat_handler | Attach the selected content to the context and ask a question.                                                                 |
| completion_handler     | Code completion                                                                                                                |
| curl_request_handler   | The simplest interaction between curl and LLM is generally used to query account balance or available model lists, etc.        |

Each handler's parameters can be referred to [here](docs/tools).

Examples can be seen [AI Tools Configuration](examples/ai-tools/)

### UI

See [UI Configuration](examples/ui/) and [nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md)

[⬆ back to top](#contents)

### Custom parsing function

For streaming output, we use our custom `streaming_handler`; for AI tools that return output results in one go, we use our custom `parse_handler`.
 
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

