local LOG = require("llm.common.log")
local utils = require("llm.tools.utils")
local diff = require("llm.common.diff_style")
local parse = require("llm.common.io.parse")
local conf = require("llm.config")
local Split = require("nui.split")

local M = {}

function M.handler(name, F, state, streaming, prompt, opts)
  if diff.style == nil then
    diff = diff:update()
  end

  local options = {
    _name = "Action",
    separator = "─",
    start_str = "```",
    end_str = "```",
    only_display_diff = false,
    enable_buffer_context = true,
    language = "English",
    templates = nil,
    url = nil,
    model = nil,
    api_type = nil,
    args = nil,
    parse_handler = nil,
    stdout_handler = nil,
    stderr_handler = nil,
    timeout = 120,
    input = {
      relative = "win",
      position = "bottom",
      size = "25%",
      enter = true,
      buf_options = {
        filetype = "llm",
        buftype = "nofile",
      },
      win_options = {
        spell = false,
        number = false,
        relativenumber = false,
        wrap = true,
        linebreak = false,
        signcolumn = "no",
      },
    },
    output = {
      relative = "editor",
      position = "right",
      size = "25%",
      enter = true,
      buf_options = {
        filetype = "llm",
        buftype = "nofile",
      },
      win_options = {
        spell = false,
        number = false,
        relativenumber = false,
        wrap = true,
        linebreak = false,
        signcolumn = "no",
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
  options.diagnostic = options.diagnostic or conf.configs.diagnostic
  options.lsp = options.lsp or conf.configs.lsp

  if prompt == nil then
    prompt = string.format(require("llm.tools.prompts").action, options.language)
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local ft = F.GetFileType()
  if options.templates and options.templates[ft] then
    prompt = prompt .. string.format("\n\n%s", options.templates[ft])
  end
  options.fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
  local mode = options.mode or vim.fn.mode()
  local lines, start_line, start_col, end_line, end_col = F.GetVisualSelectionRange(bufnr, mode, options)
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

  local default_actions = {}

  -- Only display diff for docstring
  if options.only_display_diff then
    state.app["session"][name] = {
      { role = "system", content = prompt },
      { role = "user", content = source_content },
    }
    options.messages = state.app.session[name]
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
      utils.new_diff(diff, options, context, ostr)
    end

    parse.GetOutput(options)
    for _, op in ipairs({ "accept", "reject", "close" }) do
      utils.set_keymapping(options[op].mapping.mode, options[op].mapping.keys, function()
        default_actions[op]()
        if options[op].action ~= nil then
          options[op]:action(options)
        end
        for _, reset_op in ipairs({ "accept", "reject", "close" }) do
          utils.clear_keymapping(options[reset_op].mapping.mode, options[reset_op].mapping.keys, bufnr)
        end
      end, bufnr)
    end
  else
    if F.IsValid(options.diagnostic) then
      state.app["session"][name] = {
        { role = "system", content = prompt },
        {
          role = "user",
          content = source_content
            .. "\n"
            .. F.GetRangeDiagnostics(
              { [bufnr] = { start_line = start_line, end_line = end_line, start_col = start_col, end_col = end_col } },
              options
            ),
        },
      }
    else
      state.app["session"][name] = {
        { role = "system", content = prompt },
        { role = "user", content = source_content },
      }
    end
    if F.IsValid(options.lsp) then
      options.lsp.bufnr_info_list = {
        bufnr = {
          start_line = start_line,
          end_line = end_line,
          ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
        },
      }
      state.input.request_with_lsp = F.lsp_wrap(options)
    end

    local preview_box = Split({
      relative = options.output.relative,
      position = options.output.position,
      size = options.output.size,
      enter = options.output.enter,
      buf_options = options.output.buf_options,
      win_options = options.output.win_options,
    })

    preview_box:mount()

    state.popwin_list[preview_box.winid] = preview_box

    local input_box = Split({
      relative = options.input.relative,
      position = options.input.position,
      size = options.input.size,
      enter = options.input.enter,
      buf_options = options.input.buf_options,
      win_options = options.input.win_options,
    })

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
        F.CancelLLM()
        if diff and diff.valid then
          diff:reject()
        end
        preview_box:unmount()
      end,
    }

    if state.input.request_with_lsp ~= nil then
      state.input.request_with_lsp(function()
        if F.IsValid(state.input.lsp_ctx.content) then
          table.insert(state.app.session[name], state.input.lsp_ctx)
        end
        options.messages = state.app.session[name]
        utils.single_turn_dialogue(preview_box, streaming, options, context, diff, default_actions)
        F.ClearAttach()
      end)
    else
      options.messages = state.app.session[name]
      utils.single_turn_dialogue(preview_box, streaming, options, context, diff, default_actions)
    end

    preview_box:map("n", "<C-c>", F.CancelLLM)

    preview_box:map(options.close.mapping.mode, options.close.mapping.keys, function()
      default_actions.close()
      if options.close.action ~= nil then
        options.close:action(options)
      end
      for _, kk in ipairs({ "accept", "reject", "close" }) do
        utils.clear_keymapping(options[kk].mapping.mode, options[kk].mapping.keys, bufnr)
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
        utils.single_turn_dialogue(preview_box, streaming, options, context, diff, default_actions)
      end)
    end)

    preview_box:map("n", { "<C-r>" }, function()
      if diff and diff.valid then
        diff:reject()
      end
      table.remove(state.app.session[name], #state.app.session[name])
      utils.single_turn_dialogue(preview_box, streaming, options, context, diff, default_actions)
    end)
  end
end
return M
