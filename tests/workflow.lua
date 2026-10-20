-- Run from the repository root: nvim --headless -u NONE -l tests/workflow.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local validation = require("config.validation_tasks")
local roots = {}
local passed = 0

local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), ("expected %s, got %s"):format(vim.inspect(expected), vim.inspect(actual)))
end

local function test(name, callback)
  callback()
  passed = passed + 1
  print("ok - " .. name)
end

local function project(scripts, files)
  local root = vim.fn.tempname()
  table.insert(roots, root)
  vim.fn.mkdir(root .. "/.git", "p")
  if scripts then
    vim.fn.writefile({ vim.json.encode({ scripts = scripts }) }, root .. "/package.json")
  end
  for path, content in pairs(files or {}) do
    local filename = root .. "/" .. path
    vim.fn.mkdir(vim.fs.dirname(filename), "p")
    vim.fn.writefile({ content }, filename)
  end
  return root
end

local function task(root, name)
  for _, template in ipairs(validation.templates(root)) do
    if template.name == name then
      return template.builder()
    end
  end
end

local function test_task(scripts, files)
  return assert(task(project(scripts, files), "Validation: test"))
end

local function run()
  test("test:ci wins over every fallback", function()
    local result = test_task({
      ["test:ci"] = "custom-ci-command",
      ["test:run"] = "vitest run",
      test = "vitest",
      ["test:unit"] = "jest",
      ["unit:test"] = "node --test",
    })
    equal({ "npm", "run", "test:ci" }, result.cmd)
    equal({ CI = "true" }, result.env)
  end)

  test("test:run wins over watch-mode test", function()
    equal({ "npm", "run", "test:run" }, test_task({ ["test:run"] = "vitest run", test = "vitest --watch" }).cmd)
  end)

  for _, script in ipairs({ "test", "test:unit", "unit:test" }) do
    test("keeps the " .. script .. " fallback without adding runner flags", function()
      local result = test_task({ [script] = "custom-wrapper --watch" })
      equal({ "npm", "run", script }, result.cmd)
      equal({ CI = "true" }, result.env)
      equal({ "default", { "timeout", timeout = 600 } }, result.components)
    end)
  end

  test("fallback order remains test, test:unit, unit:test", function()
    equal(
      { "npm", "run", "test" },
      test_task({ test = "custom", ["test:unit"] = "custom", ["unit:test"] = "custom" }).cmd
    )
    equal({ "npm", "run", "test:unit" }, test_task({ ["test:unit"] = "custom", ["unit:test"] = "custom" }).cmd)
  end)

  for _, manager in ipairs({
    { lock = "pnpm-lock.yaml", cmd = { "pnpm", "run", "test:run" } },
    { lock = "yarn.lock", cmd = { "yarn", "test:run" } },
    { lock = "bun.lock", cmd = { "bun", "run", "test:run" } },
    { lock = "bun.lockb", cmd = { "bun", "run", "test:run" } },
  }) do
    test("preserves the package manager for " .. manager.lock, function()
      equal(manager.cmd, test_task({ ["test:run"] = "custom-command" }, { [manager.lock] = "" }).cmd)
    end)
  end

  test("all steps are bounded and aggregate retains order and test environment", function()
    local root = project(
      { lint = "eslint .", typecheck = "tsc --noEmit", test = "vitest", jscpd = "jscpd ." },
      { ["openspec/config.yaml"] = "", ["pytest.ini"] = "[pytest]", [".agents/bin/verify"] = "#!/bin/sh\nexit 0" }
    )
    assert(vim.fn.setfperm(root .. "/.agents/bin/verify", "rwx------") == 1)
    local aggregate = assert(task(root, "Validation: all"))
    equal("orchestrator", aggregate.strategy[1])
    equal({ "default", { "timeout", timeout = (600 + 30) * 7 } }, aggregate.components)
    local categories = {}
    for _, child in ipairs(aggregate.strategy.tasks) do
      table.insert(categories, child.metadata.category)
      equal(root, child.cwd)
      equal({ "default", { "timeout", timeout = 600 } }, child.components)
      equal(child.metadata.category == "test" and { CI = "true" } or nil, child.env)
    end
    equal({ "openspec", "lint", "typecheck", "test", "jscpd", "pytest", "agent-verify" }, categories)
  end)

  test("custom timeout applies to individual and aggregated steps", function()
    vim.g.validation_timeout = 1800
    local root = project({ test = "custom" })
    equal(1800, task(root, "Validation: test").components[2].timeout)
    equal(1800, task(root, "Validation: all").strategy.tasks[1].components[2].timeout)
    equal(1830, task(root, "Validation: all").components[2].timeout)
    vim.g.validation_timeout = nil
  end)

  test("aggregate startup grace is configurable without changing leaf limits", function()
    vim.g.validation_timeout = 1
    vim.g.validation_timeout_grace = 2
    local root = project({ test = "custom", jscpd = "custom" })
    local aggregate = task(root, "Validation: all")
    equal(6, aggregate.components[2].timeout)
    for _, child in ipairs(aggregate.strategy.tasks) do
      equal(1, child.components[2].timeout)
    end
    vim.g.validation_timeout = nil
    vim.g.validation_timeout_grace = nil
  end)

  test("does not invent a test task or pipeline", function()
    equal(nil, task(project({ lint = "eslint ." }), "Validation: test"))
    equal({}, validation.templates(project(nil)))
    equal({}, validation.templates(project(nil, { ["package.json"] = "invalid json" })))
  end)

  test("OpenCode spec avoids lazy.nvim's implicit setup contract", function()
    local specs = dofile("lua/plugins/opencode.lua")
    local plugin = specs[2]
    equal("NickvanDyke/opencode.nvim", plugin[1])
    equal(nil, plugin.opts)
    equal(nil, plugin.config)
    vim.opt.autoread = false
    plugin.init()
    equal(true, vim.opt.autoread:get())

    -- Verify existing callbacks without loading OpenCode or sending prompts.
    local calls = {}
    package.loaded.opencode = {
      ask = function(prompt)
        table.insert(calls, { "ask", prompt })
      end,
      prompt = function(prompt)
        table.insert(calls, { "prompt", prompt })
      end,
      select = function()
        table.insert(calls, { "select" })
      end,
    }
    package.loaded["snacks.terminal"] = {
      toggle = function(cmd, opts)
        equal("opencode", cmd)
        equal({ win = { position = "right", width = 80 } }, opts)
        table.insert(calls, { "terminal" })
      end,
    }
    for _, mapping in ipairs(plugin.keys) do
      mapping[2]()
    end
    equal({
      { "terminal" },
      { "ask", "@this: " },
      { "ask", "@buffer: " },
      { "ask", "@this: " },
      { "prompt", "Explain @this and its context" },
      { "select" },
    }, calls)
  end)

  test("keeps intentional Neotest watch separate", function()
    local watched
    package.loaded.neotest = {
      watch = {
        toggle = function(path)
          watched = path
        end,
      },
    }
    for _, mapping in ipairs(dofile("lua/plugins/neotest.lua")[1].keys) do
      if mapping[1] == "<leader>Tw" then
        mapping[2]()
        equal(vim.fn.expand("%"), watched)
        return
      end
    end
    error("Neotest watch mapping missing")
  end)
end

local ok, err = xpcall(run, debug.traceback)
for _, root in ipairs(roots) do
  vim.fn.delete(root, "rf")
end
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print(("%d regression checks passed"):format(passed))
