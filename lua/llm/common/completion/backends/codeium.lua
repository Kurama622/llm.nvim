local codeium = require("codeium.source")

function codeium:init(opts)
  self.opts = opts

  function self.get_trigger_characters()
    return { "@", ".", "(", "[", ":", " " }
  end

  function self.get_keyword_pattern()
    if self.opts.only_trigger_by_keywords then
      return "^$"
    end
  end

  return self
end

return codeium
