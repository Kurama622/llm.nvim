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


# 目录
<!-- mtoc-start -->

* [截图](#截图)
* [安装](#安装)
  * [依赖](#依赖)
  * [准备工作](#准备工作)
    * [Cloudflare](#cloudflare)
    * [ChatGLM (智谱清言)](#chatglm-智谱清言)
    * [kimi (月之暗面)](#kimi-月之暗面)
    * [Github Models](#github-models)
    * [siliconflow (硅基流动)](#siliconflow-硅基流动)
    * [Deepseek](#deepseek)
    * [openrouter](#openrouter)
    * [本地运行的大模型](#本地运行的大模型)
  * [基本配置](#基本配置)
  * [窗口风格配置](#窗口风格配置)
  * [AI工具的配置](#ai工具的配置)
  * [本地运行大模型](#本地运行大模型)
* [默认快捷键](#默认快捷键)
* [作者的配置文件](#作者的配置文件)
* [常见问题](#常见问题)
  * [windows的curl使用格式与linux不一样，llm.nvim默认的请求格式，windows下会有问题](#windows的curl使用格式与linux不一样llmnvim默认的请求格式windows下会有问题)
  * [多个大模型切换，频繁更改LLM_KEY的值很麻烦，而且我不想在Neovim的配置文件中暴露我的Key](#多个大模型切换频繁更改llm_key的值很麻烦而且我不想在neovim的配置文件中暴露我的key)
  * [不同解析函数的优先级](#不同解析函数的优先级)
  * [AI生成git commit信息的功能如何与lazygit集成在一起?](#ai生成git-commit信息的功能如何与lazygit集成在一起)

<!-- mtoc-end -->

## 截图

1. **聊天界面**

<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-chat-compress.png" alt="llm-chat" width="560">
</p>

2. **快速翻译**
<p align= "center">
  <img src="https://github.com/user-attachments/assets/4c98484a-f0af-45ae-9b62-ea0069ccbf60" alt="llm-translate" width="560">
</p>

3. **解释代码**
<p align= "center">
  <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-explain-code-compress.png" alt="llm-explain-code" width="560">
</p>

4. **优化代码**
  - **并排展示**
  <p align= "center">
    <img src="https://github.com/Kurama622/screenshot/blob/master/llm/llm-optimize-code-compress.png" alt="llm-optimize-code" width="560">
  </p>

  - **以diff的形式展示**
  <p align= "center">
    <img src="https://github.com/user-attachments/assets/35c105b3-a2a9-4a6c-887c-cb20b77b3264" alt="llm-optimize-compare-action" width="560">
  </p>

5. **生成测试用例**
<p align= "center">
  <img src="https://github.com/user-attachments/assets/b288e3c9-7d25-40cb-8645-14dacb571529" alt="test-case" width="560">
</p>

6. **AI翻译**
<p align= "center">
  <img src="https://github.com/user-attachments/assets/ff90b1b4-3c2c-40e6-9321-4bab134710ec" alt="llm-trans" width="560">
</p>

7. **生成git commit信息**
<p align= "center">
  <img src="https://github.com/user-attachments/assets/261b21c5-0df0-48c2-916b-07f5ce0c981d" alt="llm-git-commit-msg" width="560">
</p>

[⬆ 返回目录](#目录)

## 安装

### 依赖

- `curl`: 请自行安装

### 准备工作

#### Cloudflare

1. 注册[cloudflare](https://dash.cloudflare.com/)，获取账户和API Key. 你可以在[这里](https://developers.cloudflare.com/workers-ai/models/)看到cloudflare的所有模型, 其中标注beta的是免费模型.

2. 在你的`zshrc`或者`bashrc`中设置`ACCOUNT` 和 `LLM_KEY`环境变量

```bash
export ACCOUNT=<Your ACCOUNT>
export LLM_KEY=<Your API_KEY>
```
#### ChatGLM (智谱清言)

1. 注册智谱清言：[https://open.bigmodel.cn/](https://open.bigmodel.cn/), 获取你的API Key.

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Your API_KEY>
```

#### kimi (月之暗面)
1. 注册月之暗面: [Moonshot AI 开放平台](https://login.moonshot.cn/?source=https%3A%2F%2Fplatform.moonshot.cn%2Fredirect&appid=dev-workbench), 获取你的API Key.

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Your API_KEY>
```

#### Github Models
1. 获取你的Github [Token](https://github.com/settings/tokens)

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Github Token>
```

#### siliconflow (硅基流动)
1. 注册硅基流动：[siliconflow](https://account.siliconflow.cn/login?redirect=https%3A%2F%2Fcloud.siliconflow.cn%2F%3F), 获取你的API Key. 你可以在[这里](https://cloud.siliconflow.cn/models)看到硅基流动上所有的模型，选择`只看免费`可以看到所有的免费模型

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Your API_KEY>
```

#### Deepseek
1. 注册Deepseek: [deepseek](https://platform.deepseek.com/api_keys), 获取你的API Key.

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Your API_KEY>
```

#### openrouter
1. 注册openrouter：[openrouter](https://openrouter.ai/), 获取你的API Key.

2. 在你的`zshrc`或者`bashrc`中设置`LLM_KEY`
```bash
export LLM_KEY=<Your API_KEY>
```

#### 本地运行的大模型
在你的`zshrc`或者`bashrc`中设置`LLM_KEY`为`NONE`
```bash
export LLM_KEY=NONE
```

[⬆ 返回目录](#目录)

### 基本配置

**一些你应该知道的命令**

- `LLMSessionToggle`: 打开/隐藏对话界面
- `LLMSelectedTextHandler`: 对选中的文本进行处理，如何处理取决于你传入什么提示词
- `LLMAppHandler`: 调用AI工具

> 如果url没有被配置，默认使用Cloudflare

```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
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
        --[[ 可选的: 如果你需要同时使用不同平台的模型，可以通过配置
                     fetch_key 来保证不同模型使用不同的API Key]]
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

        -- [[ local llm ]]
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
    - 整个对话界面
      - `Session:Toggle`: 打开/隐藏对话界面
      - `Session:Close`: 关闭对话界面
  - *分割窗口风格下的快捷键*
    - 输出窗口
      - `Output:Ask`: 打开输入窗口
      - `Output:Cancel`: 取消对话
      - `Output:Resend`: 重新回答

如果你使用本地运行的大模型（但不是用ollama运行的），你可能需要定义streaming_handler（必须），以及parse_handler（非必需，只有个别AI工具会用到），具体见[本地运行大模型](#本地运行大模型)

[⬆ 返回目录](#目录)

### 窗口风格配置

如果你想进一步配置对话界面的样式，你可以分别对`input_box_opts`、`output_box_opts`、`history_box_opts`和`popwin_opts`进行配置。

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

更多信息可以查阅[nui/popup](https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md)

```lua
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        style = "float", -- right | left | above | below | float

        -- [[ Github Models ]]
        url = "https://models.inference.ai.azure.com/chat/completions",
        model = "gpt-4o",
        api_type = "openai",

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
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      { "<leader>ae", mode = "v", "<cmd>LLMSelectedTextHandler 请解释下面这段代码<cr>" },
      { "<leader>t", mode = "x", "<cmd>LLMSelectedTextHandler 英译汉<cr>" },
    },
  },
```

[⬆ 返回目录](#目录)

### AI工具的配置

目前llm.nvim提供了一些AI工具的模板，方便大家去自定义自己的AI工具

所有的AI工具都需要定义在`app_handler`中，以一对`key-value`的形式呈现，`key`为工具名称，`value`为工具的配置信息

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
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
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
              args = [=[return string.format([[curl %s -N -X POST -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d '%s']], url, LLM_KEY, vim.fn.json_encode(body))]=],
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

[⬆ 返回目录](#目录)

### 本地运行大模型

本地大模型需要自定义解析函数，对于流式输出，我们使用自定义的`streaming_handler`；对于一次性返回输出结果的AI工具，我们使用自定义的`parse_handler`

下面是`ollama`运行`llama3.2:1b`的样例
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
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
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
| Output+Input | `<leader>ac` | `n`      | 打开/隐藏对话界面       |
| Output+Input | `<esc>`      | `n`      | 关闭对话界面            |

- 分割窗口风格下的快捷键

| 窗口         | 按键         | 模式     | 描述                    |
| ------------ | ------------ | -------- | ----------------------- |
| Input        | `<cr>`       | `n`      | 提交你的问题            |
| Output       | `i`          | `n`      | 打开输入窗口            |
| Output       | `ctrl+c`     | `n`      | 取消本轮对话            |
| Output       | `ctrl+r`     | `n`      | 重新发起本轮对话        |

[⬆ 返回目录](#目录)

## 作者的配置文件

[plugins/llm.lua](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/llm.lua)

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
          return switch("enable_glm")
        end,
        url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        model = "glm-4-flash",
        api_type = "zhipu",
        args = [=[return string.format([[curl %s -N -X POST -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d '%s']], url, LLM_KEY, vim.fn.json_encode(body))]=],
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

- 在zshrc或者bashrc中加载`.env`，并定义一些函数，用于切换不同的大模型
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

- 最后在llm.nvim配置文件中，添加`switch`函数
  ```lua
  local function switch(shell_func)
    -- [LINK] https://github.com/Kurama622/dotfiles/blob/main/zsh/module/func.zsh
    local p = io.popen(string.format("source ~/.config/zsh/module/func.zsh; %s; echo $LLM_KEY", shell_func))
    local key = p:read()
    p:close()
    return key
  end
  ```
  通过`fetch_key`完成Key的切换
  ```lua
    fetch_key = function()
      return switch("enable_glm")
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
