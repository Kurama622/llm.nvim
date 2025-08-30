local fio = {}

function fio.CreateDir(path)
  local dir = io.open(path, "rb")
  if dir then
    dir:close()
  else
    vim.fn.mkdir(path, "p")
  end
end

return fio
