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
      local pattern = string.format("%s(.-)%s", start_str, end_str)
      local res = ostr:match(pattern)
      if res == nil then
        print("The code block format is incorrect, please manually copy the generated code.")
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
    language = "English",
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})

  if prompt == nil then
    prompt = string.format(
      [[Optimize the code, correct syntax errors, make the code more concise, and enhance reusability.

Provide optimization ideas and the complete code after optimization. Mark the output code block with # BEGINCODE and # ENDCODE.

The indentation of the optimized code should remain consistent with the original code. Here is an example:

The original code is:
<space><space><space><space>def func(a, b)
<space><space><space><space><space><space><space><space>return a + b

Optimization ideas:
1. The function name `func` is not clear. Based on the context, it is determined that this function is meant to implement the functionality of adding two numbers, so the function name is changed to `add`.
2. There is a syntax issue in the function definition; it should end with a colon. It should be `def add(a, b):`.

Since the original code is indented by N spaces, the optimized code is also indented by N spaces.

The optimized code is:

```<language>
# BEGINCODE
<space><space><space><space>def add(a, b):
<space><space><space><space><space><space><space><space>return a + b
# ENDCODE
```

Please optimize this code according to the format, and respond in %s.]],
      options.language
    )
  end

  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
  local lines, start_line, start_col, end_line, end_col = F.GetVisualSelectionRange(bufnr)
  local source_content = F.GetVisualSelection(lines)

  F.VisMode2NorMode()

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

  local start_str = "# BEGINCODE\n"
  local end_str = "\n# ENDCODE"

  state.app["session"][name] = {}
  table.insert(state.app.session[name], { role = "system", content = prompt })
  table.insert(state.app.session[name], { role = "user", content = source_content })

  state.popwin = preview_box

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

  local worker =
    single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)

  preview_box:map("n", "<C-c>", function()
    if worker.job then
      worker.job:shutdown()
      worker.job = nil
    end
  end)

  preview_box:map("n", { "Y", "y" }, function()
    if diff then
      diff:accept()
    end
  end)

  preview_box:map("n", { "N", "n" }, function()
    if diff then
      diff:reject()
    end
  end)

  preview_box:map("n", { "<esc>" }, function()
    if worker.job then
      worker.job:shutdown()
      worker.job = nil
    end
    if diff then
      diff:reject()
    end
    preview_box:unmount()
  end)

  preview_box:map("n", { "I", "i" }, function()
    input_box:mount()
    vim.api.nvim_command("startinsert")
    input_box:map("n", { "<esc>" }, function()
      input_box:unmount()
    end)

    input_box:map("n", { "Y", "y" }, function()
      if diff then
        diff:accept()
      end
    end)

    input_box:map("n", { "N", "n" }, function()
      if diff then
        diff:reject()
      end
    end)

    input_box:map("n", { "<CR>" }, function()
      local contents = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
      table.remove(state.app.session[name], #state.app.session[name])
      state.app.session[name][#state.app.session[name]].content = state.app.session[name][#state.app.session[name]].content
        .. "\n"
        .. table.concat(contents, "\n")
      vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
      worker =
        single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)
    end)
  end)

  preview_box:map("n", { "<C-r>" }, function()
    table.remove(state.app.session[name], #state.app.session[name])
    worker = single_turn_dialogue(preview_box, state, name, streaming, fetch_key, options, start_str, end_str, context)
  end)
end

function M.side_by_side_handler(name, F, state, streaming, prompt, opts)
  local ft = vim.bo.filetype
  if prompt == nil then
    prompt = [[优化代码, 修改语法错误, 让代码更简洁, 增强可复用性，
            你要像copliot那样，直接给出代码内容, 不要使用代码块或其他标签包裹!

            下面是一个例子，假设我们需要优化下面这段代码:
            void test() {
             return 0
            }

            输出格式应该为：
            int test() {
              return 0;
            }

            请按照格式，帮我优化这段代码：]]
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

  state.app["session"][name] = {}
  table.insert(state.app.session[name], { role = "user", content = prompt .. "\n" .. source_content })

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

  preview_box:map("n", { "<esc>", "N", "n" }, function()
    if worker.job then
      worker.job:shutdown()
      print("Suspend output...")
      vim.wait(200, function() end)
      worker.job = nil
    end
    layout:unmount()
  end)

  preview_box:map("n", { "Y", "y" }, function()
    vim.api.nvim_command("normal! ggVGky")
    layout:unmount()
  end)
end

function M.qa_handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = [[请帮我把这段话翻译成英语, 直接给出翻译结果: ]]
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

  state.app["session"][name] = {}
  input_box:map("n", "<enter>", function()
    -- clear preview_box content [optional]
    vim.api.nvim_buf_set_lines(preview_box.bufnr, 0, -1, false, {})

    local input_table = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
    local input = table.concat(input_table, "\n")

    -- clear input_box content
    vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
    if input ~= "" then
      table.insert(state.app.session[name], { role = "user", content = prompt .. "\n" .. input })
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

  for _, v in ipairs({ input_box, preview_box }) do
    v:map("n", { "<esc>", "N", "n" }, function()
      if worker.job then
        worker.job:shutdown()
        print("Suspend output...")
        vim.wait(200, function() end)
        worker.job = nil
      end
      layout:unmount()
    end)

    v:map("n", { "Y", "y" }, function()
      vim.api.nvim_set_current_win(preview_box.winid)
      vim.api.nvim_command("normal! ggVGky")
      layout:unmount()
    end)
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
  }

  options = vim.tbl_deep_extend("force", options, opts or {})

  local content = prompt
  if options.apply_visual_selection then
    content = content .. ":\n" .. F.GetVisualSelection()
  end

  content = (content:gsub(".", {
    ["'"] = "''",
  }))
  local flexible_box = nil

  state.app.session[name] = {}
  table.insert(state.app.session[name], { role = "user", content = content })
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  if options.exit_handler == nil then
    options.exit_handler = function(output)
      flexible_box = F.FlexibleWindow(output, options.enter_flexible_window)
      flexible_box:mount()
      flexible_box:map("n", { "<esc>", "N", "n" }, function()
        flexible_box:unmount()
      end)
      flexible_box:map("n", { "Y", "y" }, function()
        vim.api.nvim_command("normal! ggVGy")
        flexible_box:unmount()
      end)

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
  -- local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  -- vim.api.nvim_feedkeys(esc, "x", false)
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

return M
