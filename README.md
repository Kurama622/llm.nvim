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
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
    config = function()
      require("llm").setup({
        prompt = "请用中文回答问题",
        max_tokens = 512,
        model = "@cf/qwen/qwen1.5-14b-chat-awq",
        prefix = {
          user = { text = "😃 ", hl = "Title" },
          llm = { text = "⚡ ", hl = "Added" },
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

https://github.com/StubbornVegeta/llm.nvim/blob/6317242e9a3cf7f5ba05c1364fa2ebf8c04ccd48/lua/llm/config.lua#L10-L108

### Example Configuration

For example, the following simple configuration can do:

- Adjust the position of `popwin`.

- Set icons and prompt.

- Remap keys.
```lua
{
  "StubbornVegeta/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  cmd = { "LLMSesionToggle", "LLMSelectedTextHandler" },
  config = function()
    require("llm").setup({
      prompt = "Please answer in English!",
      max_tokens = 512,
      model = "@cf/qwen/qwen1.5-14b-chat-awq",

      prefix = {
        user = { text = "😃 ", hl = "Title" },
        llm = { text = "⚡ ", hl = "Added" },
      },

      -- The pop-up window of LLMSelectedTextHandler is popwin
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
}
```
