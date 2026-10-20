-- Requires existing plugins at their lazy-lock.json revisions. Never installs.
-- LAZYVIM_TEST_PLUGINS=/path/to/lazy nvim --headless -u NONE -l tests/integration.lua
local plugin_root = assert(vim.env.LAZYVIM_TEST_PLUGINS, "Set LAZYVIM_TEST_PLUGINS to the installed plugins directory")
local lock = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
for _, name in ipairs({ "lazy.nvim", "opencode.nvim", "snacks.nvim", "overseer.nvim" }) do
  local sha = vim.fn.system({ "git", "-C", plugin_root .. "/" .. name, "rev-parse", "HEAD" }):gsub("%s+$", "")
  assert(sha == lock[name].commit, name .. " must match lazy-lock.json")
end

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/.git", "p")
local tasks = {}
local function run()
  vim.env.XDG_CACHE_HOME = root .. "/cache"
  vim.env.XDG_STATE_HOME = root .. "/state"
  vim.env.XDG_DATA_HOME = root .. "/data"
  vim.go.loadplugins = true
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  vim.opt.runtimepath:prepend(plugin_root .. "/lazy.nvim")
  local specs = dofile("lua/plugins/opencode.lua")
  specs[2].dir = plugin_root .. "/opencode.nvim"
  specs[2].dependencies[1].dir = plugin_root .. "/snacks.nvim"
  local errors = {}
  local notify = vim.notify
  vim.notify = function(message, level, opts)
    if level == vim.log.levels.ERROR then
      table.insert(errors, message)
    else
      notify(message, level, opts)
    end
  end
  require("lazy").setup({
    spec = specs,
    root = plugin_root,
    lockfile = root .. "/lazy-lock.json",
    state = root .. "/lazy-state.json",
    install = { missing = false },
    checker = { enabled = false },
    change_detection = { enabled = false },
    rocks = { enabled = false },
    readme = { enabled = false },
    performance = { cache = { enabled = false }, rtp = { reset = false } },
  })
  require("lazy").load({ plugins = { "opencode.nvim" } })
  vim.wait(50, function()
    return #errors > 0
  end)
  assert(#errors == 0, table.concat(errors, "\n"))
  assert(require("lazy.core.config").plugins["opencode.nvim"]._.loaded, "OpenCode did not load")
  assert(require("opencode").setup == nil, "Revisit the loader regression test: upstream now has setup()")
  assert(vim.opt.autoread:get(), "OpenCode init did not enable autoread")
  print("ok - pinned lazy.nvim loads OpenCode and Snacks without setup errors")

  vim.opt.runtimepath:prepend(plugin_root .. "/overseer.nvim")
  local overseer = require("overseer")
  overseer.setup({ dap = false })
  local validation = require("config.validation_tasks")
  local function pipeline(scripts, expected, marker, change)
    vim.fn.writefile({ vim.json.encode({ scripts = scripts }) }, root .. "/package.json")
    local template = validation.templates(root)[1]
    assert(template.name == "Validation: all")
    local definition = template.builder()
    if change then
      change(definition)
    end
    local task = overseer.new_task(definition)
    table.insert(tasks, task)
    assert(task:start(), "Pipeline failed to start")
    assert(
      vim.wait(10000, function()
        return task:is_complete()
      end, 20),
      "Pipeline did not reach a terminal state"
    )
    assert(task.status == expected, "Expected " .. expected .. ", got " .. task.status)
    assert((vim.uv.fs_stat(root .. "/after-test") ~= nil) == marker, "Unexpected later-step execution")
    return task
  end

  -- All scripts are local Node fixtures; no dependencies are installed.
  local after = [[node -e "require('fs').writeFileSync('after-test', 'done')"]]
  local finite = [[node -e "process.exit(process.env.CI === 'true' ? 0 : 1)"]]
  local watch = [[node -e "setInterval(() => {}, 1000)"]]
  vim.g.validation_timeout = 5
  pipeline({ ["test:ci"] = finite, test = watch, jscpd = after }, "SUCCESS", true)
  print("ok - finite test:ci wins, receives CI=true, and the next step runs")
  vim.fn.delete(root .. "/after-test")
  pipeline({ ["test:run"] = finite, test = watch, jscpd = after }, "SUCCESS", true)
  print("ok - finite test:run wins and the next step runs")
  vim.fn.delete(root .. "/after-test")
  pipeline({ test = [[node -e "process.exit(1)"]], jscpd = after }, "FAILURE", false)
  print("ok - a failing test stops the pipeline before later steps")

  vim.g.validation_timeout = 1
  vim.g.validation_timeout_grace = 1
  package.preload["overseer.component.test_startup_delay"] = function()
    return {
      constructor = function()
        return {
          on_pre_start = function()
            -- Model startup/transition work outside each child's timeout.
            vim.uv.sleep(750)
            vim.uv.update_time()
          end,
        }
      end,
    }
  end
  pipeline({ test = finite, jscpd = after }, "SUCCESS", false, function(definition)
    for _, child in ipairs(definition.strategy.tasks) do
      child.cmd = { "node", "-e", "setTimeout(() => {}, 750)" }
      table.insert(child.components, "test_startup_delay")
    end
  end)
  print("ok - startup overhead does not consume the sequential checks' per-step allowance")

  local canceled = pipeline({ test = watch, jscpd = after }, "CANCELED", false)
  local child_ids = canceled.strategy.tasks
  assert(overseer.list_tasks()[1], "Expected Overseer task state")
  assert(require("overseer.task_list").get(child_ids[1][1]).status == "CANCELED")
  assert(require("overseer.task_list").get(child_ids[2][1]).status == "PENDING")
  print("ok - a watch-mode fallback times out as CANCELED, not SUCCESS, and later steps stay pending")
  pipeline({ test = finite, jscpd = after }, "CANCELED", false, function(definition)
    definition.strategy.tasks[1].cmd = { root .. "/missing-executable" }
  end)
  print("ok - the aggregate deadline also cancels a command that cannot start")
  vim.notify = notify
end

local ok, err = xpcall(run, debug.traceback)
for _, task in ipairs(tasks) do
  task:stop()
  task:dispose(true)
end
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print("7 pinned-plugin integration checks passed")
