<p align="center">
  <img src="https://github.com/Kurama622/screenshot/raw/master/llm/llm-logo-light-purple-font.png" alt="llm.nvim" width="345">
</p>
<p align="center">
  <a href="README.md">English</a> |
  <a href="README_CN.md"><b>简体中文</b></a>
</p>

---

> [!IMPORTANT]
> 大语言模型插件，让你在Neovim中与大模型交互
>
> 1. 支持任意一款大模型，比如GPT，GLM，Kimi、DeepSeek、Gemini、Qwen或者本地运行的大模型(比如ollama)
>
> 2. 支持定义属于你自己的AI工具，且不同工具可以使用不同的模型
>
> 3. 最重要的一点，你可以使用任何平台提供的免费模型（比如`Cloudflare`，`Github models`，`siliconflow`、`openrouter`或者其他的平台）

> [!NOTE]
> 不同大模型的配置(比如**ollama**, **deepseek**)、 界面的配置、以及AI工具的配置(包括**代码补全**) 请先查阅 [examples](examples). 这里有你想知道的大部分内容。在使用插件之前，应该确保你的`LLM_KEY`是有效的，并且该环境变量已经生效。
>
> [wiki](https://github.com/Kurama622/llm.nvim/wiki)和[docs](./docs/)也可能对你有用。

> 用户QQ群：1037412539


# 目录
<!-- mtoc-start -->

* [截图](#截图)
  * [聊天界面](#聊天界面)
  * [快速翻译](#快速翻译)
  * [解释代码](#解释代码)
  * [随机提问](#随机提问)
  * [给对话附加上下文](#给对话附加上下文)
  * [优化代码](#优化代码)
  * [生成测试用例](#生成测试用例)
  * [AI翻译](#ai翻译)
  * [图像识别](#图像识别)
  * [生成git commit信息](#生成git-commit信息)
  * [生成docstring](#生成docstring)
  * [联网搜索](#联网搜索)
  * [代码补全](#代码补全)
* [安装](#安装)
  * [依赖](#依赖)
  * [准备工作](#准备工作)
    * [不同AI平台的官网](#不同ai平台的官网)
  * [最小安装示例](#最小安装示例)
* [配置](#配置)
  * [Commands](#commands)
  * [模型参数](#模型参数)
  * [快捷键](#快捷键)
  * [工具](#工具)
  * [UI](#ui)
  * [自定义解析函数](#自定义解析函数)
* [待办](#待办)
* [作者的配置文件](#作者的配置文件)
* [致谢](#致谢)
  * [特别鸣谢](#特别鸣谢)

<!-- mtoc-end -->

## 截图

### 聊天界面

[模型配置](./examples/chat/) | [界面配置](./examples/ui/)

- 浮动风格
<p align= "center">
  <img src="https://github.com/user-attachments/assets/f488f87a-fc65-49ea-9574-29721b224adb" alt="llm-float-ui" width="800">
</p>

- 分屏风格
<p align= "center">
  <img src="https://github.com/user-attachments/assets/1225fc3c-c975-4f9b-b6ed-17dae10709a1" alt="llm-split-ui" width="800">
</p>

### [快速翻译](./examples/ai-tools/Word-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/4c98484a-f0af-45ae-9b62-ea0069ccbf60" alt="llm-translate" width="800">
</p>

### 解释代码

[流式输出](./examples/chat/deepseek/config.lua#L52) | [非流式输出](./examples/ai-tools/Code-Explain/config.lua)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="800">
</p>

### [随机提问](./examples/ai-tools/Ask/config.lua)

> 一次性，不保留历史记录

你可以配置 [inline_assistant](./examples/ai-tools/Ask/config.lua) 来决定是否展示diff (默认按'd'展示)

<p align= "center">
  <img src="https://github.com/user-attachments/assets/e3300e1f-dbd2-4978-bd60-ddf9106257cb" alt="llm-ask" width="800">
</p>

### [给对话附加上下文](./examples/ai-tools/Attach-To-Chat/config.lua)

你可以配置 [inline_assistant](./examples/ai-tools/Ask/config.lua) 来决定是否展示diff (默认按'd'展示)

<p align= "center">
  <img src="https://github.com/user-attachments/assets/33ba7517-6cf1-4e52-b6b4-27e6a4fb1148" alt="llm-attach" width="800">
</p>

### 优化代码
  - [**并排展示**](./examples/ai-tools/Optimize-Code/config.lua)
  <p align= "center">
    <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="800">
  </p>

  - [**以diff的形式展示**](./examples/ai-tools/Optimize-Code-and-Display-Diff/config.lua)
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/35c105b3-a2a9-4a6c-887c-cb20b77b3264" alt="llm-optimize-compare-action" width="800">
  </p>

### [生成测试用例](./examples/ai-tools/Generate-Test-Cases/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/b288e3c9-7d25-40cb-8645-14dacb571529" alt="test-case" width="800">
</p>

### [AI翻译](./examples/ai-tools/AI-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/ff90b1b4-3c2c-40e6-9321-4bab134710ec" alt="llm-trans" width="800">
</p>

### [图像识别](./examples/ai-tools/Formula-Recognition/README.md)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/95edeacf-feca-4dfe-bb75-02538a62c83e" alt="llm-images" width="800">
</p>

### [生成git commit信息](./examples/ai-tools/AI-Commit-Messages/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/261b21c5-0df0-48c2-916b-07f5ce0c981d" alt="llm-git-commit-msg" width="800">
</p>

### [生成docstring](./examples/ai-tools/Generate-Docstring/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/a1ae0ba7-d914-4bcd-a136-b88d79f7eb91" alt="llm-docstring" width="800">
</p>

### [联网搜索](./docs/cmds/README.md#web_search)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/acf57069-a561-4f23-ba89-f666193dcde4" alt="web-search" width="800">
</p>

### [代码补全](./examples/ai-tools/Code-Completions/)
  - **虚拟文本**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/9215ba1c-df62-4ca8-badb-cf4b62262c57" alt="completion-virtual-text" width="800">
  </p>

  - **blink.cmp 或 nvim-cmp**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/93ef3c02-799d-435e-81fa-c4bf7df936d9" alt="completion-blink-cmp" width="800">
  </p>

[⬆ 返回目录](#目录)

## 安装

### 依赖

- `curl`: 请自行安装
- `fzf >= 0.37.0`: 可选的，split风格预览会话历史以及图像识别工具选择图片会依赖fzf（作者用的0.39.0）
- `render-markdown.nvim`: 可选的。更好的markdown预览依赖此插件。

```lua
{
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", branch = "main" },
      "nvim-mini/mini.icons",
    }, -- if you use standalone mini plugins
    ft = { "markdown", "llm" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig

    config = function()
      require("render-markdown").setup({
        restart_highlighter = true,
        heading = {
          enabled = true,
          sign = false,
          position = "overlay", -- inline | overlay
          icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
          signs = { "󰫎 " },
          width = "block",
          left_margin = 0,
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
          border = false,
          border_virtual = false,
          border_prefix = false,
          above = "▄",
          below = "▀",
          backgrounds = {},
          foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
          },
        },
        dash = {
          enabled = true,
          icon = "─",
          width = 0.5,
          left_margin = 0.5,
          highlight = "RenderMarkdownDash",
        },
        code = { style = "normal" },
      })
    end,
  }
```

### 准备工作


1. 在官网注册并获取你的API Key (Cloudflare 需要额外获取你的 account).

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`环境变量(Cloudflare 需要额外设置 `ACCOUNT`)

```bash
export LLM_KEY=<Your API_KEY>
export ACCOUNT=<Your ACCOUNT> # just for cloudflare
```

#### 不同AI平台的官网

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

| 平台                   | 获取API Key的链接                                                                                                           | 备注                                                                                                                    |
| -----------            | ----------                                                                                                                  | -------                                                                                                                 |
| Cloudflare             | [https://dash.cloudflare.com/](https://dash.cloudflare.com/)                                                                | 你可以在[这里](https://developers.cloudflare.com/workers-ai/models/)看到cloudflare的所有模型, 其中标注beta的是免费模型. |
| ChatGLM(智谱清言)      | [https://open.bigmodel.cn/](https://open.bigmodel.cn/)                                                                      |                                                                                                                         |
| Kimi(月之暗面)        | [Moonshot AI 开放平台](https://login.moonshot.cn/?source=https%3A%2F%2Fplatform.moonshot.cn%2Fredirect&appid=dev-workbench) |                                                                                                                         |
| Github Models          | [Github Token](https://github.com/settings/tokens)                                                                          |                                                                                                                         |
| siliconflow (硅基流动) | [siliconflow](https://account.siliconflow.cn/login?redirect=https%3A%2F%2Fcloud.siliconflow.cn%2F%3F)                       | 你可以在[这里](https://cloud.siliconflow.cn/models)看到硅基流动上所有的模型，选择`只看免费`可以看到所有的免费模型       |
| Deepseek               | [https://platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)                                            |                                                                                                                         |
| Openrouter             | [https://openrouter.ai/](https://openrouter.ai/)                                                                            |                                                                                                                         |
| Chatanywhere           | [https://api.chatanywhere.org/v1/oauth/free/render](https://api.chatanywhere.org/v1/oauth/free/render)                      | 每天200次免费调用GPT-4o-mini.                                                                                           |

</details>

**对于本地大模型, 在`zshrc` or `bashrc`中设置 `LLM_KEY` 为 `NONE`.**

[⬆ 返回目录](#目录)


### 最小安装示例

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

**[配置模板](./basic_template.lua)**

## 配置

### Commands

| Cmd                      | Description                                  |
| ---                      | -----                                        |
| `LLMSessionToggle`       | 打开/隐藏聊天界面                            |
| `LLMSelectedTextHandler` | 处理所选文本，其处理方式取决于您输入的提示词 |
| `LLMAppHandler`          | 调用AI工具                                   |

### 模型参数

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

| Parameter          | Description                                                                              | Value                                                                                                                                       |
| ------------------ | -------                                                                                  | -                                                                                                                                           |
| url                | 请求地址                                                                                 | String                                                                                                                                      |
| model              | 模型名                                                                                   | String                                                                                                                                      |
| api_type           | 输出解析格式                                                                             | `workers-ai` \| `zhipu`\|<br>`openai`\| `ollama`                                                                                            |
| timeout            | 响应最大超时时间 (单位: 秒)                                                              | Number                                                                                                                                      |
| fetch_key          | API KEY或者返回API KEY的函数                                                             | Function \| String                                                                                                                            |
| max_tokens         | 响应的最大token数                                                                        | Number                                                                                                                                      |
| temperature        | 取值范围0到1。值越小，回复越贴近主题; 值越大，回复越发散，但太高的值也容易使回复偏离主题 | Number                                                                                                                                      |
| top_p              | 取值范围0到1。值越高，回复越多样化，重复性越低。(也越容易产生偏离主题的回复)             | Number                                                                                                                                      |
| enable_thinking    | 启用thinking功能 (模型本身需要支持thinking)                                              | Boolean                                                                                                                                     |
| thinking_budget    | 思考过程的最大token长度 (仅在 `enable_thinking` 为真时生效)                              | Number                                                                                                                                      |
| schema             | Function-calling 所需的函数参数描述                                                      | Table                                                                                                                                       |
| functions_tbl      | Function-calling 所需的函数字典                                                          | Table                                                                                                                                       |
| keep_alive         | 保持连接 (一般用于ollama)                                                                | see [keep_alive/OLLAMA_KEEP_ALIVE](https://github.com/ollama/ollama/blob/c02db93243353855b983db2a1562a02b57e66db1/docs/faq.md?plain=1#L214) |
| streaming_handler  | 自定义流式输出的解析格式                                                                 | Function                                                                                                                                    |
| parse_handler      | 自定义非流式输出的解析格式                                                               | Function                                                                                                                                    |

</details>


### 快捷键

<details>
<summary><b><i>Expand the table.</i></b></summary>
<br/>

| Style       | Keyname           | Description                                                       | Default: `[mode] keymap` | Window                                       |
| -           | -                 | -                                                                 | -                        | -                                            |
| float       | Input:Submit      | 提交问题                                                          | `[i] ctrl+g`             | Input                                        |
| float       | Input:Cancel      | 中止对话请求                                                      | `[i] ctrl+c`             | Input                                        |
| float       | Input:Resend      | 重新请求                                                          | `[i] ctrl+r`             | Input                                        |
| float       | Input:HistoryNext | 选择下一个历史会话                                                | `[i] ctrl+j`             | Input                                        |
| float       | Input:HistoryPrev | 选择上一个历史会话                                                | `[i] ctrl+k`             | Input                                        |
| float       | Input:ModelsNext  | 选择下一个模型                                                    | `[i] ctrl+shift+j`       | Input                                        |
| float       | Input:ModelsPrev  | 选择上一个模型                                                    | `[i] ctrl+shift+k`       | Input                                        |
| split       | Output:Ask        | 打开输入窗口。normal 模式下, 按回车提交问题                       | `[n] i`                  | Output                                       |
| split       | Output:Cancel     | 中止对话请求                                                      | `[n] ctrl+c`             | Output                                       |
| split       | Output:Resend     | 重新请求                                                          | `[n] ctrl+r`             | Output                                       |
| float/split | Session:Toggle    | 打开/隐藏聊天界面                                                 | `[n] <leader>ac`         | Input+Output                                 |
| float/split | Session:Close     | 关闭聊天界面                                                      | `[n] <esc>`              | `float`: Input+Output<br>`split`: Output     |
| float/split | Session:New       | 创建一个新的会话                                                  | `[n] <C-n>`              | `float`: Input+Output<br>`split`: Output     |
| float/split | Session:Models    | 打开模型列表窗口                                                  | `[n] ctrl+m`             | `float`: App input window<br>`split`: Output |
| split       | Session:History   | 打开会话历史窗口: 移动遵循fzf的配置, `<cr>` 确认选择, `<esc>`关闭 | `[n] ctrl+h`             | Output                                       |
| float       | Focus:Input       | 从输出窗口切换到输入窗口                                          | -                        | Output                                       |
| float       | Focus:Output      | 从输入窗口切换到输出窗口                                          | -                        | Input                                        |
| float       | PageUp            | 输出窗口向上翻页                                                  | `[n/i] Ctrl+b`           | Input                                        |
| float       | PageDown          | 输出窗口向下翻页                                                  | `[n/i] Ctrl+f`           | Input                                        |
| float       | HalfPageUp        | 输出窗口向上翻半页                                                | `[n/i] Ctrl+u`           | Input                                        |
| float       | HalfPageDown      | 输出窗口向下翻半页                                                | `[n/i] Ctrl+d`           | Input                                        |
| float       | JumpToTop         | 定位到输出窗口顶部                                                | `[n] gg`                 | Input                                        |
| float       | JumpToBottom      | 定位到输出窗口低部                                                | `[n] G`                  | Input                                        |

</details>

### 工具

| Handler name           | Description                                                                |
| --                     | --                                                                         |
| side_by_side_handler   | 用两个并排的窗口来展示结果                                                 |
| action_handler         | 在原文件中展示AI建议代码和原代码的diff                                     |
| qa_handler             | 单轮对话的问答                                                             |
| flexi_handler          | 结果将在一个弹性窗口中显示（窗口大小根据输出文本的量自动计算）             |
| disposable_ask_handler | 灵活的提问，您可以选择一段代码进行提问，或者直接提问（当前缓冲区是上下文） |
| attach_to_chat_handler | 将选择的文本附加到Chat会话的上下文                                         |
| completion_handler     | 代码补全                                                                   |
| curl_request_handler   | 与LLM之间最简单的交互通常用于查询账户余额或可用的模型列表等                |

**每个handler的具体参数参考[docs/tools](docs/tools).**

示例： [AI 工具配置](examples/ai-tools/)

### UI

参考 [UI 配置](examples/ui/) 和 [nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md)

[⬆ 返回目录](#目录)

### 自定义解析函数

对于流式输出，我们使用自定义的`streaming_handler`；对于一次性返回输出结果的AI工具，我们使用自定义的`parse_handler`

下面是`ollama`运行`llama3.2:1b`的样例

<details>
<summary><b><i>展开代码</i></b></summary>
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
    local status, data = pcall(vim.json.decode, ctx.line)
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

[⬆ 返回目录](#目录)

## 待办

[todo-list](https://github.com/Kurama622/llm.nvim/issues/44)

[⬆ 返回目录](#目录)

## 作者的配置文件

[plugins/llm](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/llm)

## 致谢

以下开源项目为llm.nvim提供了宝贵的灵感和参考:

- [olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim): diff的显示风格以及大模型提示词
- [SmiteshP/nvim-navbuddy](https://github.com/SmiteshP/nvim-navbuddy): 部分界面设计
- [milanglacier/minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim): 代码补全功能

### 特别鸣谢

[ACKNOWLEDGMENTS](./ACKNOWLEDGMENTS.md)
