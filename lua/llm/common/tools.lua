local M = {}

local event = require("nui.utils.autocmd").event
local Popup = require("nui.popup")
local Split = require("nui.split")
local Layout = require("nui.layout")
local NuiText = require("nui.text")
local conf = require("llm.config")
local F = require("llm.common.func")
local seamless = require("llm.common.seamless_border")
local diff = require("llm.common.diff_style")
local LOG = require("llm.common.log")
local completion = require("llm.common.completion")

local function set_keymapping(mode, keymaps, callback, bufnr)
  for _, key in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, "", { callback = callback })
  end
end

local function clear_keymapping(mode, keymaps, bufnr)
  for _, key in pairs(keymaps) do
    vim.keymap.del(mode, key, { buffer = bufnr })
  end
end

local function overwrite_selection(context, contents)
  if context.start_col > 0 then
    context.start_col = context.start_col - 1
  end

  vim.api.nvim_buf_set_text(
    context.bufnr,
    context.start_line - 1,
    context.start_col,
    context.end_line - 1,
    context.end_col,
    contents
  )
  vim.api.nvim_win_set_cursor(context.winnr, { context.start_line, context.start_col })
end

local function single_turn_dialogue(
  preview_box,
  state,
  name,
  streaming,
  fetch_key,
  options,
  start_str,
  end_str,
  context
)
  F.AppendChunkToBuffer(preview_box.bufnr, preview_box.winid, "-----\n")

  return streaming(
    preview_box.bufnr,
    preview_box.winid,
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    options.args,
    options.streaming_handler,
    options.stdout_handler,
    options.stderr_handler,
    function(ostr)
      local pattern = string.format("%s%%w*\n(.-)\n%s", start_str, end_str)
      local res = ""
      for match in ostr:gmatch(pattern) do
        res = res .. match
      end
      if res == nil then
        LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
      end
      local contents = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, true)

      if res then
        overwrite_selection(context, vim.split(res, "\n"))
      end
      diff = diff.new({
        bufnr = context.bufnr,
        cursor_pos = context.cursor_pos,
        filetype = context.filetype,
        contents = contents,
        winnr = context.winnr,
      })
    end
  )
end

function M.action_handler(name, F, state, streaming, prompt, opts)
  if conf.configs.display.diff.provider == "default" then
    diff = require("llm.common.diff_style.default")
  elseif conf.configs.display.diff.provider == "mini_diff" then
    diff = require("llm.common.diff_style.mini_diff")
  end

  local options = {
    separator = "─",
    only_display_diff = false,
    language = "English",
    templates = nil,
    url = nil,
    model = nil,
    api_type = nil,
    args = nil,
    parse_handler = nil,
    stdout_handler = nil,
    stderr_handler = nil,
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})

  if prompt == nil then
    prompt = string.format(
      [[You are an AI programming assistant.

Your core tasks include:
- Code quality and adherence to best practices
- Potential bugs or edge cases
- Performance optimizations
- Readability and maintainability
- Any security concerns

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.
- Avoid line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- The **INDENTATION FORMAT** of the optimized code remains exactly the **SAME** as the original code.
- All non-code responses must use %s.

When given a task:
1. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
2. Output the code in a **SINGLE** code block, being careful to only return relevant code.]],
      options.language
    )
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local ft = F.GetFileType()
  if options.templates and options.templates[ft] then
    prompt = prompt .. string.format("\n\n%s", options.templates[ft])
  end
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
  local lines, start_line, start_col, end_line, end_col = F.GetVisualSelectionRange(bufnr)
  local source_content = F.GetVisualSelection(lines)

  F.VisMode2NorMode()

  local context = {
    bufnr = bufnr,
    filetype = F.GetFileType(bufnr),
    contents = lines,
    winnr = winnr,
    cursor_pos = cursor_pos,
    start_line = start_line,
    start_col = start_col,
    end_line = end_line,
    end_col = end_col,
  }
  local start_str = "```"
  local end_str = "```"

  state.app["session"][name] = {
    { role = "system", content = prompt },
    { role = "user", content = source_content },
  }
  local default_actions = {}
  if options.only_display_diff then
    default_actions = {
      accept = function()
        if diff and diff.valid then
          diff:accept()
        end
      end,
      reject = function()
        if diff and diff.valid then
          diff:reject()
        end
      end,
      close = function()
        if diff and diff.valid then
          diff:reject()
        end
      end,
    }
    options.exit_handler = function(ostr)
      local pattern = string.format("%s%%w*\n(.-)\n%s", start_str, end_str)
      local res = ""
      for match in ostr:gmatch(pattern) do
        res = res .. match
      end
      if res == nil then
        LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
      end
      local contents = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, true)

      if res then
        overwrite_selection(context, vim.split(res, "\n"))
      end
      diff = diff.new({
        bufnr = context.bufnr,
        cursor_pos = context.cursor_pos,
        filetype = context.filetype,
        contents = contents,
        winnr = context.winnr,
      })
    end

    F.GetUrlOutput(
      state.app.session[name],
      fetch_key,
      options.url,
      options.model,
      options.api_type,
      options.args,
      options.parse_handler,
      options.stdout_handler,
      options.stderr_handler,
      options.exit_handler
    )
  else
    local preview_box = Split({
      relative = options.output.relative,
      position = options.output.position,
      size = options.output.size,
      enter = options.output.enter,
      buf_options = {
        filetype = "markdown",
        buftype = options.output.buftype,
      },
      win_options = {
        spell = options.output.spell,
        number = options.output.number,
        relativenumber = options.output.relativenumber,
        wrap = options.output.wrap,
        linebreak = options.output.linebreak,
        signcolumn = options.output.signcolumn,
      },
    })

    preview_box:mount()

    state.popwin = preview_box

    local input_box = Split({
      relative = options.input.relative,
      position = options.input.position,
      size = options.input.size,
      enter = options.input.enter,
      buf_options = {
        filetype = "markdown",
        buftype = options.input.buftype,
      },
      win_options = {
        spell = options.input.spell,
        number = options.input.number,
        relativenumber = options.input.relativenumber,
        wrap = options.input.wrap,
        linebreak = options.input.linebreak,
        signcolumn = options.input.signcolumn,
      },
    })
    local worker =
      single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)

    preview_box:map("n", "<C-c>", function()
      if worker.job then
        worker.job:shutdown()
        LOG:INFO("Suspend output...")
        worker.job = nil
      end
    end)

    default_actions = {
      accept = function()
        if diff and diff.valid then
          diff:accept()
        end
      end,
      reject = function()
        if diff and diff.valid then
          diff:reject()
        end
      end,
      close = function()
        if worker.job then
          worker.job:shutdown()
          LOG:INFO("Suspend output...")
          worker.job = nil
        end
        if diff and diff.valid then
          diff:reject()
        end
        preview_box:unmount()
      end,
    }

    preview_box:map(options.close.mapping.mode, options.close.mapping.keys, function()
      default_actions.close()
      if options.close.action ~= nil then
        options.close.action()
      end
      for _, kk in ipairs({ "accept", "reject", "close" }) do
        clear_keymapping(options[kk].mapping.mode, options[kk].mapping.keys, bufnr)
      end
    end)

    preview_box:map("n", { "I", "i" }, function()
      input_box:mount()
      if diff and diff.valid then
        diff:reject()
      end
      vim.api.nvim_command("startinsert")
      input_box:map("n", { "<esc>" }, function()
        input_box:unmount()
      end)

      input_box:map("n", { "<CR>" }, function()
        local contents = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
        table.remove(state.app.session[name], #state.app.session[name])
        state.app.session[name][1].content = state.app.session[name][1].content .. "\n" .. table.concat(contents, "\n")
        vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
        worker =
          single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)
      end)
    end)

    preview_box:map("n", { "<C-r>" }, function()
      if diff and diff.valid then
        diff:reject()
      end
      table.remove(state.app.session[name], #state.app.session[name])
      worker =
        single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)
    end)
  end

  for _, k in ipairs({ "accept", "reject", "close" }) do
    set_keymapping(options[k].mapping.mode, options[k].mapping.keys, function()
      default_actions[k]()
      if options[k].action ~= nil then
        options[k].action()
      end
      if k == "close" then
        for _, kk in ipairs({ "accept", "reject", "close" }) do
          clear_keymapping(options[kk].mapping.mode, options[kk].mapping.keys, bufnr)
        end
      end
    end, bufnr)
  end
end

function M.side_by_side_handler(name, F, state, streaming, prompt, opts)
  local ft = vim.bo.filetype
  if prompt == nil then
    prompt = [[You are an AI programming assistant.

Your core tasks include:
- Code quality and adherence to best practices
- Potential bugs or edge cases
- Performance optimizations
- Readability and maintainability
- Any security concerns

You must:
- Follow the user's requirements carefully and to the letter.
- DO NOT use Markdown formatting in your answers.
- Avoid wrapping the output in triple backticks.
- The **INDENTATION FORMAT** of the optimized code remains exactly the **SAME** as the original code.

When given a task:
- ONLY OUTPUT THE RELEVANT CODE.]]
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local source_content = F.GetVisualSelection()

  local options = {
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local source_box = F.CreatePopup(options.left.title, false, options.left)
  local preview_box = F.CreatePopup(options.right.title, true, options.right)

  local layout = F.CreateLayout(
    "80%",
    "55%",
    Layout.Box({
      Layout.Box(source_box, { size = "50%" }),
      Layout.Box(preview_box, { size = "50%" }),
    }, { dir = "row" })
  )

  layout:mount()

  F.SetBoxOpts({ source_box, preview_box }, {
    filetype = { ft, ft },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  state.popwin = source_box
  F.WriteContent(source_box.bufnr, source_box.winid, source_content)

  state.app["session"][name] = {
    { role = "system", content = prompt },
    { role = "user", content = source_content },
  }

  state.popwin = preview_box
  local worker = streaming(
    preview_box.bufnr,
    preview_box.winid,
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    options.args,
    options.streaming_handler,
    options.stdout_handler,
    options.stderr_handler,
    options.exit_handler
  )

  preview_box:map("n", "<C-c>", function()
    if worker.job then
      worker.job:shutdown()
      worker.job = nil
    end
  end)

  local default_actions = {
    accept = function()
      vim.api.nvim_set_current_win(preview_box.winid)
      vim.api.nvim_command("normal! ggVGky")
    end,
    reject = function() end,
    close = function() end,
  }
  for _, v in ipairs({ source_box, preview_box }) do
    for _, k in ipairs({ "accept", "reject", "close" }) do
      v:map(options[k].mapping.mode, options[k].mapping.keys, function()
        if worker.job then
          worker.job:shutdown()
          LOG:INFO("Suspend output...")
          vim.wait(200, function() end)
          worker.job = nil
        end
        if options[k].action ~= nil then
          options[k].action()
        else
          default_actions[k]()
        end
        layout:unmount()
      end)
    end
  end
end

function M.qa_handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = [[请帮我把这段话翻译成英语, 直接给出翻译结果: ]]
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local options = {
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    component_width = "60%",
    component_height = "55%",
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  vim.api.nvim_set_hl(0, "LLMQuery", options.query.hl)

  local input_box = Popup({
    enter = true,
    border = {
      style = seamless.get_border_chars("rounded", "top"),
      text = {
        top = NuiText(options.query.title, "LLMQuery"),
        top_align = "center",
      },
    },
    win_options = options.input_box_opts.win_options,
  })

  local preview_box = Popup({
    focusable = true,
    border = {
      style = seamless.get_border_chars("rounded", "bottom"),
      text = { top = "", top_align = "center" },
    },
    win_options = options.preview_box_opts.win_options,
  })

  local layout = F.CreateLayout(
    options.component_width,
    options.component_height,
    Layout.Box({
      Layout.Box(input_box, { size = options.input_box_opts.size }),
      Layout.Box(preview_box, { size = options.preview_box_opts.size, { grow = 1 } }),
    }, { dir = "col" })
  )

  layout:mount()
  vim.api.nvim_command("startinsert")

  F.SetBoxOpts({ preview_box }, {
    filetype = { "markdown", "markdown" },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  local worker = { job = nil }

  input_box:map("n", "<enter>", function()
    -- clear preview_box content [optional]
    vim.api.nvim_buf_set_lines(preview_box.bufnr, 0, -1, false, {})

    local input_table = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
    local input = table.concat(input_table, "\n")

    -- clear input_box content
    vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
    if input ~= "" then
      state.app.session[name] = {
        { role = "system", content = prompt },
        { role = "user", content = input },
      }
      state.popwin = preview_box
      worker = streaming(
        preview_box.bufnr,
        preview_box.winid,
        state.app.session[name],
        fetch_key,
        options.url,
        options.model,
        options.api_type,
        options.args,
        options.streaming_handler,
        options.stdout_handler,
        options.stderr_handler,
        options.exit_handler
      )
    end
  end)

  input_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(preview_box.winid)
  end)
  preview_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(input_box.winid)
  end)

  local default_actions = {
    accept = function()
      vim.api.nvim_set_current_win(preview_box.winid)
      vim.api.nvim_command("normal! ggVGky")
    end,
    reject = function() end,
    close = function() end,
  }

  for _, v in ipairs({ input_box, preview_box }) do
    for _, k in ipairs({ "accept", "reject", "close" }) do
      v:map(options[k].mapping.mode, options[k].mapping.keys, function()
        if worker.job then
          worker.job:shutdown()
          LOG:INFO("Suspend output...")
          vim.wait(200, function() end)
          worker.job = nil
        end
        if options[k].action ~= nil then
          options[k].action()
        else
          default_actions[k]()
        end
        layout:unmount()
      end)
    end
  end
end

function M.curl_request_handler(url, args)
  for _, v in ipairs(args) do
    url = url .. " " .. v
  end
  local cmd = string.format("curl -s %s ", url)
  local pipe = io.popen(cmd)
  local res = nil
  if pipe ~= nil then
    res = vim.json.decode(pipe:read())
    pipe:close()
  end
  return res
end

function M.flexi_handler(name, F, state, _, prompt, opts)
  local options = {
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    exit_on_move = false,
    enter_flexible_window = true,
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})

  if type(prompt) == "function" then
    prompt = (prompt():gsub(".", {
      ["'"] = "''",
    }))
  end

  local content = ""
  if options.apply_visual_selection then
    content = (F.GetVisualSelection():gsub(".", {
      ["'"] = "''",
    }))
  end

  local flexible_box = nil

  if content == "" then
    state.app.session[name] = { { role = "user", content = prompt } }
  else
    state.app.session[name] = { { role = "system", content = prompt }, { role = "user", content = content } }
  end
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  if options.exit_handler == nil then
    options.exit_handler = function(output)
      flexible_box = F.FlexibleWindow(output, options.enter_flexible_window, options.win_opts)
      if flexible_box then
        flexible_box:mount()
      else
        LOG:ERROR(string.format('your model output is "%s"', output))
        return
      end

      local default_actions = {
        accept = function()
          vim.api.nvim_command("normal! ggVGy")
        end,
        reject = function() end,
        close = function() end,
      }
      -- set keymaps and action
      for _, v in ipairs({ "accept", "reject", "close" }) do
        flexible_box:map(options[v].mapping.mode, options[v].mapping.keys, function()
          if options[v].action ~= nil then
            options[v].action()
          else
            default_actions[v]()
          end
          flexible_box:unmount()
        end)
      end

      F.SetBoxOpts({ flexible_box }, {
        filetype = { "markdown", "markdown" },
        buftype = options.buftype,
        spell = options.spell,
        number = options.number,
        wrap = options.wrap,
        linebreak = options.linebreak,
      })
    end
  end

  F.GetUrlOutput(
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    options.args,
    options.parse_handler,
    options.stdout_handler,
    options.stderr_handler,
    options.exit_handler
  )

  F.VisMode2NorMode()
  if options.exit_on_move then
    vim.api.nvim_create_autocmd("CursorMoved", {
      callback = function()
        if flexible_box ~= nil then
          flexible_box:unmount()
        end
      end,
    })
  end
end

function M.completion_handler(name, F, state, _, prompt, opts)
  local options = {
    fim = true,
    context_window = 12800,
    context_ratio = 0.75,
    stream = false,
    parse_handler = nil,
    stdout_handler = nil,
    stderr_handler = nil,
    timeout = 10,
    throttle = 1000, -- only send the request every x milliseconds, use 0 to disable throttle.
    -- debounce the request in x milliseconds, set to 0 to disable debounce
    debounce = 400,
    filetypes = {},
    default_filetype_enabled = true,
    auto_trigger = true,
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
        toggle = {
          mode = "n",
          keys = "<leader>cp",
        },
      },
    },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})

  options.timeout = tostring(options.timeout)
  completion:init(options)
end

return M
