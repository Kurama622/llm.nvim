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

function fio.ScanDir(_dir)
  local uv = vim.uv or vim.loop
  local cwd = _dir
  local ignore_dirs = {
    [".git"] = true,
    ["build"] = true,
    ["Cache"] = true,
    ["cache"] = true,
    [".cache"] = true,
    [".local"] = true,
    ["node_modules"] = true,
  }

  local function scan_dir(dir, result)
    result = result or {}

    local handle = uv.fs_scandir(dir)
    if not handle then
      return result
    end

    while true do
      local name, t = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      if t == "directory" and ignore_dirs[name] then
        goto continue
      end

      local path = dir .. "/" .. name

      if t == "directory" then
        scan_dir(path, result)
      elseif t == "file" then
        table.insert(result, vim.fs.relpath(cwd, path))
      end

      ::continue::
    end
    return result
  end

  return scan_dir(_dir)
end

return fio
