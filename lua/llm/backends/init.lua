local F = require("llm.common.api")
local LOG = require("llm.common.log")
local backends = {
  msg_tool_calls_content = {},
}

function backends.get_streaming_handler(streaming_handler, api_type, configs, ctx)
  if streaming_handler then
    return function(chunk)
      if debug.getinfo(streaming_handler, "u").nparams == 3 then
        return streaming_handler(chunk, ctx, F)
      else
        vim.notify(
          "[Deprecated Usage] Please refer to the latest examples: https://github.com/Kurama622/llm.nvim?tab=readme-ov-file#local-llm-configuration ",
          vim.log.levels.WARN,
          {
            title = "llm.nvim",
          }
        )
        return streaming_handler(chunk, ctx.line, ctx.assistant_output, ctx.bufnr, ctx.winid, F)
      end
    end
  elseif api_type then
    if api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").StreamingHandler(chunk, ctx)
      end
    elseif api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").StreamingHandler(chunk, ctx)
      end
    elseif api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").StreamingHandler(chunk, ctx)
      end
    elseif api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").StreamingHandler(chunk, ctx)
      end
    end
  elseif configs.streaming_handler then
    return function(chunk)
      if debug.getinfo(configs.streaming_handler, "u").nparams == 3 then
        return configs.streaming_handler(chunk, ctx, F)
      else
        return configs.streaming_handler(chunk, ctx.line, ctx.assistant_output, ctx.bufnr, ctx.winid, F)
      end
    end
  elseif configs.api_type then
    if configs.api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").StreamingHandler(chunk, ctx)
      end
    elseif configs.api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").StreamingHandler(chunk, ctx)
      end
    elseif configs.api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").StreamingHandler(chunk, ctx)
      end
    elseif configs.api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").StreamingHandler(chunk, ctx)
      end
    end
  end
end

function backends.get_parse_handler(parse_handler, api_type, configs, ctx)
  if parse_handler then
    return function(chunk)
      local success, err = pcall(function()
        ctx.assistant_output = parse_handler(chunk)
      end)

      if success then
        return ctx.assistant_output
      else
        LOG:TRACE(chunk)
        LOG:ERROR("Error occurred:", err)
        return ""
      end
    end
  elseif api_type then
    if api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").ParseHandler(chunk, ctx)
      end
    elseif api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").ParseHandler(chunk, ctx)
      end
    elseif api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").ParseHandler(chunk, ctx)
      end
    elseif api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").ParseHandler(chunk, ctx)
      end
    end
  elseif configs.parse_handler then
    return function(chunk)
      local success, err = pcall(function()
        ctx.assistant_output = configs.parse_handler(chunk)
      end)

      if success then
        return ctx.assistant_output
      else
        LOG:TRACE(chunk)
        LOG:ERROR("Error occurred:", err)
        return ""
      end
    end
  elseif configs.api_type then
    if configs.api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").ParseHandler(chunk, ctx)
      end
    elseif configs.api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").ParseHandler(chunk, ctx)
      end
    elseif configs.api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").ParseHandler(chunk, ctx)
      end
    elseif configs.api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").ParseHandler(chunk, ctx)
      end
    end
  end
end

function backends.get_function_calling(api_type, configs, ctx)
  local function handle_api_type(type)
    local api_handlers = {
      ["workers-ai"] = function(chunk)
        LOG:ERROR("Workers_ai do not support function-calling.")
      end,
      ["zhipu"] = function(chunk)
        LOG:ERROR("GLM do not support function-calling.")
      end,
      ["openai"] = function(chunk)
        return require("llm.backends.openai").FunctionCalling(ctx, chunk)
      end,
      ["ollama"] = function(chunk)
        return require("llm.backends.ollama").FunctionCalling(ctx, chunk)
      end,
    }
    return api_handlers[type] or nil
  end
  return handle_api_type(api_type) or handle_api_type(configs.api_type)
end

function backends.get_tools_respond(api_type, configs, ctx)
  local function handle_api_type(type)
    local api_handlers = {
      ["workers-ai"] = function(chunk)
        LOG:ERROR("Workers_ai do not support function-calling.")
      end,
      ["zhipu"] = function(chunk)
        LOG:ERROR("GLM do not support function-calling.")
      end,
      ["openai"] = ctx.stream and function(chunk)
        return require("llm.backends.openai").AppendToolsRespond(chunk, backends.msg_tool_calls_content)
      end or function(chunk)
        return require("llm.backends.openai").GetToolsRespond(chunk, backends.msg_tool_calls_content)
      end,
      ["ollama"] = ctx.stream and function(chunk)
        return require("llm.backends.ollama").AppendToolsRespond(chunk, backends.msg_tool_calls_content)
      end or function(chunk)
        return require("llm.backends.ollama").GetToolsRespond(chunk, backends.msg_tool_calls_content)
      end,
    }

    return api_handlers[type] or nil
  end

  return handle_api_type(api_type) or handle_api_type(configs.api_type)
end

function backends.gen_msg_with_tool_calls(api_type, configs, ctx)
  local function handle_api_type(type)
    local api_handlers = {
      ["workers-ai"] = function()
        LOG:ERROR("Workers_ai do not support function-calling.")
      end,
      ["zhipu"] = function()
        LOG:ERROR("GLM do not support function-calling.")
      end,
      ["openai"] = {
        choices = {
          {
            message = {
              role = "assistant",
              content = ctx.assistant_output,
              tool_calls = backends.msg_tool_calls_content,
            },
          },
        },
      },
      ["ollama"] = {
        message = {
          role = "assistant",
          content = ctx.assistant_output,
          tool_calls = backends.msg_tool_calls_content,
        },
      },
    }

    return api_handlers[type] or nil
  end

  return handle_api_type(api_type) or handle_api_type(configs.api_type)
end

return backends
