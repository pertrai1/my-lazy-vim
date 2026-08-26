local M = {}

local uv = vim.uv or vim.loop

local SCRIPT_CANDIDATES = {
  { category = "lint", names = { "lint", "check:lint", "lint:check", "lint:all" } },
  { category = "typecheck", names = { "typecheck", "type-check", "check-types", "check:typecheck" } },
  { category = "test", names = { "test", "test:unit", "unit:test", "test:ci" } },
  { category = "jscpd", names = { "jscpd", "check:duplication", "duplication:check" } },
}

local function path_join(...)
  return vim.fs.joinpath(...)
end

local function stat(path)
  return path and uv.fs_stat(path) or nil
end

local function exists(path)
  return stat(path) ~= nil
end

local function is_dir(path)
  local info = stat(path)
  return info and info.type == "directory" or false
end

local function is_executable(path)
  return vim.fn.executable(path) == 1
end

local function read_json(path)
  if not exists(path) then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  return ok and decoded or nil
end

local function read_text(path)
  if not exists(path) then
    return nil
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

local function detect_root(start_dir)
  return vim.fs.root(start_dir, { ".git", "package.json", "pyproject.toml", "uv.lock", "openspec" }) or start_dir
end

local function package_manager(root)
  if exists(path_join(root, "pnpm-lock.yaml")) then
    return { "pnpm", "run" }
  end
  if exists(path_join(root, "yarn.lock")) then
    return { "yarn" }
  end
  if exists(path_join(root, "bun.lock")) or exists(path_join(root, "bun.lockb")) then
    return { "bun", "run" }
  end
  return { "npm", "run" }
end

local function command_with_args(parts, extra)
  local cmd = vim.deepcopy(parts)
  vim.list_extend(cmd, extra)
  return cmd
end

local function task_definition(name, root, cmd, metadata)
  return {
    name = name,
    builder = function()
      return {
        name = name,
        cmd = cmd,
        cwd = root,
        components = { "default" },
        metadata = metadata or {},
      }
    end,
  }
end

local function first_script(scripts, names)
  for _, name in ipairs(names) do
    if scripts[name] then
      return name
    end
  end
end

local function script_tasks(root, tasks)
  local package_json = read_json(path_join(root, "package.json"))
  local scripts = package_json and package_json.scripts or nil
  if not scripts then
    return
  end

  local runner = package_manager(root)
  for _, candidate in ipairs(SCRIPT_CANDIDATES) do
    local script = first_script(scripts, candidate.names)
    if script then
      local cmd = command_with_args(runner, { script })
      table.insert(tasks, task_definition("Validation: " .. candidate.category, root, cmd, { category = candidate.category }))
    end
  end
end

local function openspec_task(root, tasks)
  if not is_dir(path_join(root, "openspec")) then
    return
  end
  table.insert(tasks, task_definition(
    "Validation: openspec",
    root,
    { "npx", "@fission-ai/openspec", "validate", "--all", "--no-interactive" },
    { category = "openspec" }
  ))
end

local function has_pytest_dependency(text)
  if not text then
    return false
  end

  local patterns = {
    "name%s*=%s*[\"']pytest[\"']",
    "[\"']pytest[><=~!%s%d._-]*[\"']",
    "%[tool%.pytest%.ini_options%]",
    "%[tool:pytest%]",
    "pytest[%w%._-]*%s*[><=~!]+",
    "^pytest%s*$",
  }

  for _, pattern in ipairs(patterns) do
    if text:find(pattern) then
      return true
    end
  end

  return false
end

local function pytest_configured(root)
  if exists(path_join(root, "pytest.ini")) then
    return true
  end

  for _, filename in ipairs({ "pyproject.toml", "setup.cfg", "tox.ini", "uv.lock", "requirements.txt", "requirements-dev.txt" }) do
    if has_pytest_dependency(read_text(path_join(root, filename))) then
      return true
    end
  end

  return false
end

local function pytest_task(root, tasks)
  if not pytest_configured(root) then
    return
  end

  local cmd = exists(path_join(root, "uv.lock")) and { "uv", "run", "pytest" } or { "python3", "-m", "pytest" }
  table.insert(tasks, task_definition("Validation: pytest", root, cmd, { category = "pytest" }))
end

local function agent_verify_task(root, tasks)
  local verify = path_join(root, ".agents", "bin", "verify")
  if not is_executable(verify) then
    return
  end
  table.insert(tasks, task_definition("Validation: verify", root, { verify }, { category = "agent-verify" }))
end

local function aggregate_task(root, tasks)
  if #tasks == 0 then
    return nil
  end

  local child_templates = vim.list_slice(tasks)

  return {
    name = "Validation: all",
    builder = function()
      local subtasks = {}
      for _, template in ipairs(child_templates) do
        table.insert(subtasks, template.builder())
      end
      return {
        name = "Validation: all",
        cwd = root,
        strategy = {
          "orchestrator",
          tasks = subtasks,
        },
        components = { "default" },
        metadata = { category = "validation-all" },
      }
    end,
  }
end

function M.templates(start_dir)
  local root = detect_root(start_dir)
  local tasks = {}

  openspec_task(root, tasks)
  script_tasks(root, tasks)
  pytest_task(root, tasks)
  agent_verify_task(root, tasks)

  local combined = aggregate_task(root, tasks)
  if combined then
    table.insert(tasks, 1, combined)
  end

  return tasks
end

return M
