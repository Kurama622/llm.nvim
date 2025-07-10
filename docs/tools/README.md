All AI tools can configure their own model parameters, in the same way as the [Chat's configuration](https://github.com/Kurama622/llm.nvim?tab=readme-ov-file#model-parameters).

- **Dependency**

```lua
local tools = require("llm.tools")
```

<!-- mtoc-start -->

* [side_by_side_handler](#side_by_side_handler)
* [action_handler](#action_handler)
* [qa_handler](#qa_handler)
* [flexi_handler](#flexi_handler)
* [disposable_ask_handler](#disposable_ask_handler)
* [attach_to_chat_handler](#attach_to_chat_handler)
* [completion_handler](#completion_handler)
* [curl_request_handler](#curl_request_handler)

<!-- mtoc-end -->


## side_by_side_handler

```lua
["Tool Name"] = {
  handler = tools.side_by_side_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    left = {
      title = " Source ",
      focusable = false,
    },
    right = {
      title = " Preview ",
      focusable = true,
      enter = true,
    },
    buftype = "nofile",
    spell = false,
    number = true,
    wrap = true,
    linebreak = false,
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```

## action_handler

```lua
["Tool Name"] = {
  handler = tools.action_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    -- Code block formatting
    start_str = "```",
    end_str = "```",

    -- Not to show the analysis process, only to show the final diff.
    only_display_diff = false,
    -- To set additional rules for different languages
    templates = nil,
    language = "English",

    -- Press "i" to open the input window, resubmit your request
    input = {
      buftype = "nofile",
      relative = "win",
      position = "bottom",
      size = "25%",
      enter = true,
      spell = false,
      number = false,
      relativenumber = false,
      wrap = true,
      linebreak = false,
      signcolumn = "no",
    },

    output = {
      buftype = "nofile",
      relative = "editor",
      position = "right",
      size = "25%",
      enter = true,
      spell = false,
      number = false,
      relativenumber = false,
      wrap = true,
      linebreak = false,
      signcolumn = "no",
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```

## qa_handler

```lua
["Tool Name"] = {
  handler = tools.qa_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,

    query = {
      title = " 󰊿 Trans ",
      hl = { link = "Define" },
    },

    -- The overall size setting of input + preview windows
    component_width = "60%",
    component_height = "55%",

    input_box_opts = {
      size = "15%",
      border = "rounded",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
    preview_box_opts = {
      size = "85%",
	  border = "rounded",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```

## flexi_handler

```lua
["Tool Name"] = {
  handler = tools.flexi_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,

    -- The window closes when the cursor moves.
    exit_on_move = false,
    -- When the result pops up, automatically focus on the result preview window.
    enter_flexible_window = true,

    -- Whether to use the selected content as the context for the language model
    -- For the feature of generating AI Commit Messages, this option should be set to false.
    apply_visual_selection = true,
    win_opts = {},
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```

## disposable_ask_handler

```lua
["Tool Name"] = {
  handler = tools.disposable_ask_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    language = "English",

    -- Whether to enable diff feature
    inline_assistant = false,
    -- Display diff
    display = {
      mapping = {
        mode = "n",
        keys = { "d" },
      },
      action = nil,
    },

    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
    border = {
      style = "rounded",
      text = {
        top = " Ask ",
        top_align = "center",
      },
    },
    position = {
      row = 0,
      col = 0,
    },
    relative = "cursor",
    size = {
      width = "50%",
      height = "5%",
    },
    enter = true,
    copy_suggestion_code = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```

## attach_to_chat_handler

```lua
["Tool Name"] = {
  handler = tools.attach_to_chat_handler,
  prompt = "xxxxxxxx",
  opts = {
    ---------------------------------------
    -- [Optional] set your model parameters
    timeout = 30,
    ---------------------------------------
    language = "English",

    -- If set to True, it will automatically convert the format to code block based on the current file's suffix.
    is_codeblock = false,
    -- Whether to enable diff feature
    inline_assistant = false,
    -- Display diff
    display = {
      mapping = {
        mode = "n",
        keys = { "d" },
      },
      action = nil,
    },

    copy_suggestion_code = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  },
}
```
## completion_handler

```lua
Completion = {
  handler = tools.completion_handler,
  opts = {
    timeout = 10,
    context_window = 12800,
    context_ratio = 0.75,
    -- only send the request every x milliseconds, use 0 to disable throttle.
    throttle = 400,
    -- debounce the request in x milliseconds, set to 0 to disable debounce
    debounce = 200,
    filetypes = {},
    default_filetype_enabled = true,
    auto_trigger = true,
    only_trigger_by_keywords = true,
    style = "virtual_text",
    keymap = {
      virtual_text = {
        accept = {
          mode = "i",
          keys = "<A-a>",
        },
        next = {
          mode = "i",
          keys = "<A-n>",
        },
        prev = {
          mode = "i",
          keys = "<A-p>",
        },
      },
      toggle = {
        mode = "n",
        keys = "<leader>cp",
      },
    },
  }
```

See the [Example](https://github.com/Kurama622/llm.nvim/tree/main/examples/ai-tools/Code-Completions)

## curl_request_handler
```lua
UserInfo = {
  handler = function()
    local key = os.getenv("SILICONFLOW_TOKEN")
    local res = tools.curl_request_handler(
      "https://api.siliconflow.cn/v1/user/info",
      { "GET", "-H", string.format("'Authorization: Bearer %s'", key) }
    )
    if res ~= nil then
      print("balance: " .. res.data.balance)
    end
  end,
}
```
