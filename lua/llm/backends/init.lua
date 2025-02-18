local F = require("llm.common.api")
local backends = {}

function backends.STREAMING_HANDLER(streaming_handler, api_type, configs, context)
  if streaming_handler then
    return function(chunk)
      if debug.getinfo(streaming_handler, "u").nparams == 3 then
        return streaming_handler(chunk, context, F)
      else
        return streaming_handler(chunk, context.line, context.assistant_output, context.bufnr, context.winid, F)
      end
    end
  elseif api_type then
    if api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").StreamingHandler(chunk, context)
      end
    elseif api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").StreamingHandler(chunk, context)
      end
    elseif api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").StreamingHandler(chunk, context)
      end
    elseif api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").StreamingHandler(chunk, context)
      end
    end
  elseif configs.streaming_handler then
    return function(chunk)
      if debug.getinfo(configs.streaming_handler, "u").nparams == 3 then
        return configs.streaming_handler(chunk, context, F)
      else
        return configs.streaming_handler(chunk, context.line, context.assistant_output, context.bufnr, context.winid, F)
      end
    end
  elseif configs.api_type then
    if configs.api_type == "workers-ai" then
      return function(chunk)
        return require("llm.backends.workers_ai").StreamingHandler(chunk, context)
      end
    elseif configs.api_type == "zhipu" then
      return function(chunk)
        return require("llm.backends.zhipu").StreamingHandler(chunk, context)
      end
    elseif configs.api_type == "openai" then
      return function(chunk)
        return require("llm.backends.openai").StreamingHandler(chunk, context)
      end
    elseif configs.api_type == "ollama" then
      return function(chunk)
        return require("llm.backends.ollama").StreamingHandler(chunk, context)
      end
    end
  end
end
return backends
