<p align="center">
  <img src="https://github.com/Kurama622/screenshot/raw/master/llm/llm-logo-light-purple-font.png" alt="llm.nvim" width="345">
</p>
<p align="center">
  <a href="README.md">English</a> |
  <a href="README_CN.md"><b>简体中文</b></a>
</p>

---

> [!IMPORTANT]
> 免费的大语言模型插件，让你在Neovim中与大模型交互
>
> 1. 支持任意一款大模型，比如gpt，glm，kimi、deepseek或者本地运行的大模型(比如ollama)
>
> 2. 支持定义属于你自己的AI工具，且不同工具可以使用不同的模型
>
> 3. 最重要的一点，你可以使用任何平台提供的免费模型（比如`Cloudflare`，`Github models`，`siliconflow`、`openrouter`或者其他的平台）

> [!NOTE]
> 不同大模型的配置(比如**ollama**, **deepseek**)、 界面的配置、以及AI工具的配置(包括**代码补全**) 请先查阅 [examples](examples). 这里有你想知道的大部分内容。在使用插件之前，应该确保你的`LLM_KEY`是有效的，并且该环境变量已经生效。

> 用户QQ群：1037412539


# 目录
<!-- mtoc-start -->

* [截图](#截图)
  * [聊天界面](#聊天界面)
  * [代码补全](#代码补全)
  * [快速翻译](#快速翻译)
  * [解释代码](#解释代码)
  * [随机提问](#随机提问)
  * [给对话附加上下文](#给对话附加上下文)
  * [优化代码](#优化代码)
  * [生成测试用例](#生成测试用例)
  * [AI翻译](#ai翻译)
  * [生成git commit信息](#生成git-commit信息)
  * [生成docstring](#生成docstring)
* [安装](#安装)
  * [依赖](#依赖)
  * [准备工作](#准备工作)
    * [不同AI平台的官网](#不同ai平台的官网)
  * [最小安装示例](#最小安装示例)
* [配置](#配置)
  * [基本配置](#基本配置)
    * [示例](#示例)
  * [窗口风格配置](#窗口风格配置)
    * [示例](#示例-1)
  * [AI工具的配置](#ai工具的配置)
    * [示例](#示例-2)
  * [本地运行大模型](#本地运行大模型)
* [默认快捷键](#默认快捷键)
  * [窗口切换](#窗口切换)
* [待办](#待办)
* [作者的配置文件](#作者的配置文件)
* [致谢](#致谢)
  * [特别鸣谢](#特别鸣谢)
* [常见问题](#常见问题)
  * [windows的curl使用格式与linux不一样，llm.nvim默认的请求格式，windows下会有问题](#windows的curl使用格式与linux不一样llmnvim默认的请求格式windows下会有问题)
  * [多个大模型切换，频繁更改LLM_KEY的值很麻烦，而且我不想在Neovim的配置文件中暴露我的Key](#多个大模型切换频繁更改llm_key的值很麻烦而且我不想在neovim的配置文件中暴露我的key)
  * [不同解析函数的优先级](#不同解析函数的优先级)
  * [AI生成git commit信息的功能如何与lazygit集成在一起?](#ai生成git-commit信息的功能如何与lazygit集成在一起)

<!-- mtoc-end -->

## 截图

### 聊天界面

[模型配置](./examples/chat/) | [界面配置](./examples/ui/)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" width="560">
</p>

### [代码补全](./examples/ai-tools/Code-Completions/)
  - **虚拟文本**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/9215ba1c-df62-4ca8-badb-cf4b62262c57" alt="completion-virtual-text" width="560">
  </p>

  - **blink.cmp 或 nvim-cmp**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/93ef3c02-799d-435e-81fa-c4bf7df936d9" alt="completion-blink-cmp" width="560">
  </p>

### [快速翻译](./examples/ai-tools/Word-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/4c98484a-f0af-45ae-9b62-ea0069ccbf60" alt="llm-translate" width="560">
</p>

### 解释代码

[流式输出](./examples/chat/deepseek/config.lua#L52) | [非流式输出](./examples/ai-tools/Code-Explain/config.lua)

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="560">
</p>

### [随机提问](./examples/ai-tools/Ask/config.lua)

> 一次性，不保留历史记录

你可以配置 [inline_assistant](./examples/ai-tools/Ask/config.lua) 来决定是否展示diff (默认按'd'展示)

<p align= "center">
  <img src="https://github.com/user-attachments/assets/e3300e1f-dbd2-4978-bd60-ddf9106257cb" alt="llm-ask" width="560">
</p>

### [给对话附加上下文](./examples/ai-tools/Attach-To-Chat/config.lua)

你可以配置 [inline_assistant](./examples/ai-tools/Ask/config.lua) 来决定是否展示diff (默认按'd'展示)

<p align= "center">
  <img src="https://github.com/user-attachments/assets/33ba7517-6cf1-4e52-b6b4-27e6a4fb1148" alt="llm-attach" width="560">
</p>

### 优化代码
  - [**并排展示**](./examples/ai-tools/Optimize-Code/config.lua)
  <p align= "center">
    <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="560">
  </p>

  - [**以diff的形式展示**](./examples/ai-tools/Optimize-Code-and-Display-Diff/config.lua)
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/35c105b3-a2a9-4a6c-887c-cb20b77b3264" alt="llm-optimize-compare-action" width="560">
  </p>

### [生成测试用例](./examples/ai-tools/Generate-Test-Cases/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/b288e3c9-7d25-40cb-8645-14dacb571529" alt="test-case" width="560">
</p>

### [AI翻译](./examples/ai-tools/AI-Translate/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/ff90b1b4-3c2c-40e6-9321-4bab134710ec" alt="llm-trans" width="560">
</p>

### [生成git commit信息](./examples/ai-tools/AI-Commit-Messages/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/261b21c5-0df0-48c2-916b-07f5ce0c981d" alt="llm-git-commit-msg" width="560">
</p>

### [生成docstring](./examples/ai-tools/Generate-Docstring/config.lua)
<p align= "center">
  <img src="https://github.com/user-attachments/assets/a1ae0ba7-d914-4bcd-a136-b88d79f7eb91" alt="llm-docstring" width="560">
</p>

[⬆ 返回目录](#目录)

## 安装

### 依赖

- `curl`: 请自行安装

### 准备工作


1. 在官网注册并获取你的API Key (Cloudflare 需要额外获取你的 account).

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`环境变量(Cloudflare 需要额外设置 `ACCOUNT`)

```bash
export LLM_KEY=<Your API_KEY>
export ACCOUNT=<Your ACCOUNT> # just for cloudflare
```

#### 不同AI平台的官网

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

## 配置
### 基本配置

**一些你应该知道的命令**

- `LLMSessionToggle`: 打开/隐藏对话界面
- `LLMSelectedTextHandler`: 对选中的文本进行处理，如何处理取决于你传入什么提示词
- `LLMAppHandler`: 调用AI工具

> 如果url没有被配置，默认使用Cloudflare

#### 示例

对于更多细节和示例，请查看[Chat Configuration](examples/chat/).

<details>
<summary><b><i>点击查看配置项的含义</i></b></summary>
<br/>

- `prompt`: 模型的提示词
- `prefix`: 对话角色的标志
- `style`: 对话窗口的样式(float即浮动窗口，其他均为分割窗口)
- `url`: 模型的API地址
- `model`: 模型的名称
- `api_type`: 模型输出的解析格式: `openai`, `zhipu`, `ollama`, `workers-ai`. `openai`的格式可以兼容大部分的模型，但`ChatGLM`只能用`zhipu`的格式去解析，`cloudflare`只能用`workers-ai`去解析。如果你使用ollama来运行模型，你可以配置`ollama`。
- `fetch_key`: 如果你需要同时使用不同平台的模型，可以通过配置`fetch_key`来保证不同模型使用不同的API Key，用法如下：
  ```lua
  fetch_key = function() return "<your api key>" end
  ```
- `max_tokens`: 模型的最大输出长度
- `save_session`: 是否保存会话历史
- `max_history`: 最多保存多少个会话
- `history_path`: 会话历史的保存路径
- `temperature`: 模型的temperature, 控制模型输出的随机性
- `top_p`: 模型的top_p, 控制模型输出的随机性
- `spinner`: 模型输出的等待动画 (非流式输出时生效)
- `display`
  - `diff`: diff的显示风格（优化代码并显示diff时生效, 截图中的风格为mini_diff, 需要安装[mini.diff](https://github.com/echasnovski/mini.diff)）

- `keys`: 不同窗口的快捷键设置，默认值见[默认快捷键](#默认快捷键)
  - *浮动窗口风格下的快捷键*
    - 输入窗口
      - `Input:Cancel`: 取消对话
      - `Input:Submit`: 提交问题
      - `Input:Resend`: 重新回答
      - `Input:HistoryNext`: 切换到下一个会话历史
      - `Input:HistoryPrev`: 切换到上一个会话历史
      - `PageUp`: 输出窗口向上翻页
      - `HalfPageUp`: 输出窗口向上翻页(半页)
      - `PageDown`: 输出窗口向下翻页
      - `HalfPageDown`: 输出窗口向下翻页(半页)
      - `JumpToTop`: 定位到输出窗口的顶部
      - `JumpToBottom`: 定位到输出窗口的底部
    - 整个对话界面
      - `Session:Toggle`: 打开/隐藏对话界面
      - `Session:Close`: 关闭对话界面
  - *分割窗口风格下的快捷键*
    - 输出窗口
      - `Output:Ask`: 打开输入窗口
      - `Output:Cancel`: 取消对话
      - `Output:Resend`: 重新回答
      - `Session:History`: 打开会话历史窗口
    - 整个对话界面
      - `Session:Toggle`: 打开/隐藏对话界面
      - `Session:Close`: 关闭对话界面

</details>

如果你使用本地运行的大模型（但不是用ollama运行的），你可能需要定义streaming_handler（必须），以及parse_handler（非必需，只有个别AI工具会用到），具体见[本地运行大模型](#本地运行大模型)

[⬆ 返回目录](#目录)

### 窗口风格配置

如果你想进一步配置对话界面的样式，你可以分别对`chat_ui_opts`和`popwin_opts`进行配置。

<details>
<summary><b><i>点击查看如何配置窗口风格</i></b></summary>
<br/>

它们的配置项都是相同的：
- `relative`:
  - `editor`: 该浮动窗口相对于当前编辑器窗口
  - `cursor`: 该浮动窗口相对于当前光标位置
  - `win` : 该浮动窗口相对于当前窗口

- `position`: 窗口的位置
- `size`: 窗口的大小
- `enter`: 窗口是否自动获得焦点
- `focusable`: 窗口是否可以获得焦点
- `zindex`: 窗口的层级
- `border` 
  - `style`: 窗口的边框样式
  - `text`: 窗口的边框文本
- `win_options`: 窗口的选项
 - `winblend`: 窗口的透明度
 - `winhighlight`: 窗口的高亮

</details>

更多信息可以查阅[nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md)

#### 示例

对于更多细节和示例，请查看[UI Configuration](examples/ui/).

[⬆ 返回目录](#目录)

### AI工具的配置

目前llm.nvim提供了一些AI工具的模板，方便大家去自定义自己的AI工具

所有的AI工具都需要定义在`app_handler`中，以一对`key-value`的形式呈现，`key`为工具名称，`value`为工具的配置信息

#### 示例

对于更多细节和示例，请查看[AI Tools Configuration](examples/ai-tools/).

<details>
<summary><b><i>点击查看如何配置AI工具</i></b></summary>
<br/>

对于所有的AI工具，它们的配置项都是基本类似的:

- `handler`: 使用哪个模板
  - `side_by_side_handler`: 两个窗口并排展示结果
  - `action_handler`: 在源文件中以diff的形式展示结果
    - `Y`/`y`: 接受LLM建议代码
    - `N`/`n`: 拒绝LLM建议代码
    - `<ESC>`: 直接退出
    - `I/i`: 输入优化的补充条件
    - `<C-r>`: 直接重新优化
  - `qa_handler`: 单轮对话的AI
  - `flexi_handler`: 结果会展示在弹性窗口中 ( 根据输出文本的内容多少自动计算窗口大小 )
  - 你也可以自定义函数
- `prompt`: AI工具的提示词
- `opts`
  - `spell`: 是否有拼写检查
  - `number`: 是否显示行号
  - `wrap`: 是否自动换行
  - `linebreak`: 是否允许从单词中间换行
  - `url`、`model`: 该AI工具使用哪个大模型
  - `api_type`: 该AI工具输出的解析类型
  - `streaming_handler`: 该AI工具使用自定义的流解析函数
  - `parse_handler`: 该AI工具使用自定义的解析函数
  - `border`：浮动窗口的边框样式
  - `accept`
    - `mapping`: 接受AI输出的按键映射
      - `mode`: 映射对应的vim模式, 默认为`n`
      - `keys`: 你的按键, 默认为`Y`/`y`
    - `action`: 接受AI输出时执行的函数，默认是复制到剪贴板
  - `reject`
    - `mapping`: 拒绝AI输出的按键映射
      - `mode`: 映射对应的vim模式, 默认为`n`
      - `keys`: 你的按键, 默认为`N`/`n`
    - `action`: 拒绝AI输出时执行的函数，默认是什么也不做或者关闭AI工具窗口
  - `close`
    - `mapping`: 关闭AI工具的按键映射
      - `mode`: 映射对应的vim模式, 默认为`n`
      - `keys`: 你的按键, 默认为`<ESC>`
    - `action`: 关闭AI工具，默认是拒绝所有AI输出并关闭AI工具窗口

**不同模板还有一些属于自己的专属配置项**

- `qa_handler`的`opts`中你还可以定义：
  - `component_width`: 组件的宽度
  - `component_height`: 组件的高度
  - `query`
      - `title`: 组件的标题，会显示在组件上方居中处
      - `hl` : 标题的高亮
  - `input_box_opts`: 输入框的窗口选项（`size`, `win_options`）
  - `preview_box_opts`: 预览框的窗口选项（`size`, `win_options`）

- `action_handler`的`opts`中你还可以定义:
  - `language`: 输出结果使用的语言（`English`/`Chinese`/`Japanese`等）
  - `input`
    - `relative`: 分割窗口的相对位置（`editor`/`win`）
    - `position`: 分割窗口的位置（`top`/`left`/`right`/`bottom`）
    - `size`: 分割窗口的比例（默认是25%）
    - `enter`: 是否自动进入窗口
  - `output`
    - `relative`: 同`input`
    - `position`: 同`input`
    - `size`: 同`input`
    - `enter`: 同`input`

- `side_by_side_handler`的`opts`中你还可以定义:
  - `left` 左窗口
    - `title`: 窗口的标题
    - `focusable`: 是否允许窗口获得焦点
    - `border`
    - `win_options`
  - `right` 右窗口
    - `title`: 窗口的标题
    - `focusable`: 是否允许窗口获得焦点
    - `border`
    - `win_options`

- `flexi_handler`的`opts`中你还可以定义:
  - `exit_on_move`: 是否在光标移动时关闭弹性窗口
  - `enter_flexible_window`: 是否在弹性窗口弹出时自动进入窗口
  - `apply_visual_selection`: 是否要在`prompt`后追加选中的文本内容

我的一些AI工具配置:
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

[⬆ 返回目录](#目录)

### 本地运行大模型

本地大模型需要自定义解析函数，对于流式输出，我们使用自定义的`streaming_handler`；对于一次性返回输出结果的AI工具，我们使用自定义的`parse_handler`

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

[⬆ 返回目录](#目录)

## 默认快捷键

- 浮动窗口风格下的快捷键

| 窗口         | 按键         | 模式     | 描述                    |
| ------------ | ------------ | -------- | ----------------------- |
| Input        | `ctrl+g`     | `i`      | 提交你的问题            |
| Input        | `ctrl+c`     | `i`      | 取消本轮对话            |
| Input        | `ctrl+r`     | `i`      | 重新发起本轮对话        |
| Input        | `ctrl+j`     | `i`      | 切换到下一个会话历史    |
| Input        | `ctrl+k`     | `i`      | 切换到上一个会话历史    |
| Input        | `Ctrl+b`     | `n`/`i`  | 输出窗口向上翻页        |
| Input        | `Ctrl+f`     | `n`/`i`  | 输出窗口向下翻页        |
| Input        | `Ctrl+u`     | `n`/`i`  | 输出窗口向上翻页(半页)  |
| Input        | `Ctrl+d`     | `n`/`i`  | 输出窗口向下翻页(半页)  |
| Input        | `gg`         | `n`      | 定位到输出窗口的顶部    |
| Input        | `G`          | `n`      | 定位到输出窗口的底部    |
| Output+Input | `<leader>ac` | `n`      | 打开/隐藏对话界面       |
| Output+Input | `<esc>`      | `n`      | 关闭对话界面            |

### 窗口切换

> 你可以使用 `<C-w><C-w>` 来切换窗口，如果你觉得这种方式不方便，你可以设置你自己的快捷键来切换窗口 (该特性没有默认快捷键)。

```lua
    -- Switch from the output window to the input window.
    ["Focus:Input"]       = { mode = "n", key = {"i", "<C-w>"} },
    -- Switch from the input window to the output window.
    ["Focus:Output"]      = { mode = { "n", "i" }, key = "<C-w>" },
```

- 分割窗口风格下的快捷键

| 窗口         | 按键         | 模式     | 描述                    |
| ------------ | ------------ | -------- | ----------------------- |
| Input        | `<cr>`       | `n`      | 提交你的问题            |
| Output       | `i`          | `n`      | 打开输入窗口            |
| Output       | `ctrl+c`     | `n`      | 取消本轮对话            |
| Output       | `ctrl+r`     | `n`      | 重新发起本轮对话        |
| Output       | `ctrl+h`     | `n`      | 打开会话历史窗口        |
| Output+Input | `<leader>ac` | `n`      | 打开/隐藏对话界面       |
| Output+Input | `<esc>`      | `n`      | 关闭对话界面            |
| History      | `j`          | `n`      | 预览下一个会话历史      |
| History      | `k`          | `n`      | 预览上一个会话历史      |
| History      | `<cr>`       | `n`      | 进入选择的会话          |
| History      | `<esc>`      | `n`      | 关闭会话历史窗口        |

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
---

## 常见问题

### windows的curl使用格式与linux不一样，llm.nvim默认的请求格式，windows下会有问题

使用自定义请求格式

- 基础对话功能以及部分AI工具（使用流式输出）自定义请求格式

  定义args参数，与prompt同层级
  ```lua
  --[[ custom request args ]]
  args = [[return {url, "-N", "-X", "POST", "-H", "Content-Type: application/json", "-H", authorization, "-d", vim.fn.json_encode(body)}]],
  ```

- AI工具（使用非流式输出）自定义请求格式

  在`opts`中定义args
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
> 需要根据你的实际情况去修改args

[⬆ 返回目录](#目录)

### 多个大模型切换，频繁更改LLM_KEY的值很麻烦，而且我不想在Neovim的配置文件中暴露我的Key

- 创建一个`.env`文件，专门保存你的各种Key。注意：此文件不要上传Github

```bash
export GITHUB_TOKEN=xxxxxxx
export DEEPSEEK_TOKEN=xxxxxxx
export SILICONFLOW_TOKEN=xxxxxxx
```

- 在zshrc或者bashrc中加载`.env`
  ```bash
  source ~/.config/zsh/.env

  # 默认使用Github Models
  export LLM_KEY=$GITHUB_TOKEN
  ```

- 最后在llm.nvim配置文件中，通过`fetch_key`完成Key的切换
  ```lua
    fetch_key = function()
      return vim.env.DEEPSEEK_TOKEN
    end,
  ```

[⬆ 返回目录](#目录)

### 不同解析函数的优先级

  AI工具配置的`streaming_handler`或者`parse_handler` > AI工具配置的`api_type` > 主配置的`streaming_handler`或者`parse_handler` > 主配置的`api_type`

[⬆ 返回目录](#目录)

### AI生成git commit信息的功能如何与lazygit集成在一起?

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

[⬆ 返回目录](#目录)
