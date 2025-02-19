local F = require("llm.common.api")
local LOG = require("llm.common.log")
local backends = {}

function backends.get_streaming_handler(streaming_handler, api_type, configs, ctx)
  if streaming_handler then
    return function(chunk)
      if debug.getinfo(streaming_handler, "u").nparams == 3 then
        return streaming_handler(chunk, ctx, F)
      else
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
        LOG:TRACE(vim.inspect(chunk))
        LOG:ERROR("Error occurred:" .. err)
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
    parse = function(chunk)
      local success, err = pcall(function()
        ctx.assistant_output = configs.parse_handler(chunk)
      end)

      if success then
        return ctx.assistant_output
      else
        LOG:TRACE(vim.inspect(chunk))
        LOG:ERROR("Error occurred:" .. err)
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

return backends
