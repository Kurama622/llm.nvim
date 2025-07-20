<!-- mtoc-start -->

* [llm.nvim cmds](#llmnvim-cmds)
  * [web_search](#web_search)

<!-- mtoc-end -->
# llm.nvim cmds

**USAGE**: use `@ + the command name` in the input window

## web_search

You can use `@web_search` to search the web for information.

**Provider**

Tavily: https://www.tavily.com

**Config**

```lua
{
  "Kurama622/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "Kurama622/nui.nvim", "Kurama622/windsurf.nvim" },
  cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
  config = function()
    web_search = {
      url = "https://api.tavily.com/search",
      fetch_key = vim.env.TAVILY_TOKEN,
      params = {
        auto_parameters = false,
        topic = "general",
        search_depth = "basic",
        chunks_per_source = 3,
        max_results = 3,
        include_answer = true,
        include_raw_content = true,
        include_images = false,
        include_image_descriptions = false,
        include_favicon = false,
      },
    },
  end,
}
```
