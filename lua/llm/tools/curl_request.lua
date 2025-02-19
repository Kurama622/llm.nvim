local M = {}
function M.handler(url, args)
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
return M
