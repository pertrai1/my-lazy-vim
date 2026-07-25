local function root()
  return vim.fs.root(0, {
    "package.json",
    "pyproject.toml",
    "pytest.ini",
    "Cargo.toml",
    "go.mod",
    "Makefile",
    ".git",
  }) or vim.uv.cwd()
end

local function exists(dir, name)
  return vim.uv.fs_stat(dir .. "/" .. name) ~= nil
end

local function js_runner(dir)
  if exists(dir, "pnpm-lock.yaml") then
    return "pnpm"
  end
  if exists(dir, "yarn.lock") then
    return "yarn"
  end
  if exists(dir, "bun.lockb") or exists(dir, "bun.lock") then
    return "bun"
  end
  return "npm"
end

local function project_test_command(dir)
  if exists(dir, "package.json") then
    return js_runner(dir) .. " test"
  end
  if exists(dir, "pyproject.toml") or exists(dir, "pytest.ini") or exists(dir, "setup.cfg") then
    return "pytest"
  end
  if exists(dir, "Cargo.toml") then
    return "cargo test"
  end
  if exists(dir, "go.mod") then
    return "go test ./..."
  end
  if exists(dir, "Makefile") then
    return "make test"
  end
  return nil
end

local function file_test_command(dir)
  local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
  if file == "''" then
    return project_test_command(dir)
  end
  if exists(dir, "package.json") then
    return js_runner(dir) .. " test -- " .. file
  end
  if exists(dir, "pyproject.toml") or exists(dir, "pytest.ini") or exists(dir, "setup.cfg") then
    return "pytest " .. file
  end
  if exists(dir, "Cargo.toml") then
    return "cargo test"
  end
  if exists(dir, "go.mod") then
    return "go test ./..."
  end
  return project_test_command(dir)
end

local function run(command)
  return function()
    local dir = root()
    local cmd = command(dir)
    if not cmd then
      Snacks.notify.warn("No project test command found")
      return
    end
    Snacks.terminal(cmd, {
      count = 7,
      cwd = dir,
      interactive = false,
      win = { position = "bottom", height = 15 },
    })
  end
end

return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>rt",
      run(project_test_command),
      desc = "Run project tests",
    },
    {
      "<leader>rT",
      run(file_test_command),
      desc = "Run current file tests",
    },
  },
}
