local fio = {}

function fio.CreateDir(path)
  local dir = io.open(path, "rb")
  if dir then
    dir:close()
  else
    vim.fn.mkdir(path, "p")
  end
end

function fio.SaveFile(path, str)
  local fp = io.open(path, "w")
  if fp then
    fp:write(str)
    fp:close()
  end
end
return fio
