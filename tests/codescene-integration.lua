-- Requires existing lazy.nvim/overseer.nvim at lazy-lock.json revisions.
-- LAZYVIM_TEST_PLUGINS=/path/to/lazy nvim --headless -u NONE -l tests/codescene-integration.lua
-- The executable named cs below is a local fixture, never the real CLI.
local plugin_root = assert(vim.env.LAZYVIM_TEST_PLUGINS, "Set LAZYVIM_TEST_PLUGINS to the installed plugins directory")
local lock = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
for _, name in ipairs({ "lazy.nvim", "overseer.nvim" }) do
  local sha = vim.fn.system({ "git", "-C", plugin_root .. "/" .. name, "rev-parse", "HEAD" }):gsub("%s+$", "")
  assert(sha == lock[name].commit, name .. " must match lazy-lock.json")
end

local root = vim.fn.tempname() .. " CodeScene project"
local original_path = vim.env.PATH
local original_notify = vim.notify
local tasks = {}
local notices = {}
local passed = 0

local function test(name, callback)
  callback()
  passed = passed + 1
  print("ok - " .. name)
end

local function run()
  vim.fn.mkdir(root .. "/bin", "p")
  vim.fn.mkdir(root .. "/src", "p")
  local result = vim.system({ "git", "-C", root, "init", "--quiet" }):wait()
  assert(result.code == 0)
  local source = root .. "/src/-sample ; $value.ts"
  vim.fn.writefile({ "const value = 1;", "function example() {}" }, source)
  vim.fn.writefile(
    vim.split(
      [[
#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const mode = fs.readFileSync('mode', 'utf8').trim();
fs.writeFileSync('called.json', JSON.stringify({ args: process.argv.slice(2), cwd: process.cwd() }));
if (mode === 'hang') setInterval(() => {}, 1000);
else if (mode === 'auth') {
  console.error('Authentication required (fixture)');
  console.error('This is multiline guidance, not a clickable finding.');
  console.error('Use the official CLI authentication instructions (fixture).');
  process.exitCode = 1;
}
else if (mode === 'error') { console.error('Unknown CLI option (fixture)'); process.exitCode = 2; }
else if (mode === 'unsupported') console.log('Unsupported language (fixture)');
else if (mode === 'clean') console.log('No Code Health issues (fixture)');
else {
  const file = process.argv[2] === 'check' ? path.relative(process.cwd(), process.argv[3]) : 'src/changed.ts';
  console.log(`\x1b[33mWarn: ${file}:2: Complex Method (fixture)\x1b[0m`);
  console.log(`Info: ${file}:1: Code Health information (fixture)`);
  console.error('Raw stderr remains visible (fixture)');
  if (mode === 'findings-nonzero') process.exitCode = 1;
}
]],
      "\n",
      { trimempty = true }
    ),
    root .. "/bin/cs"
  )
  assert(vim.fn.setfperm(root .. "/bin/cs", "rwx------") == 1)
  vim.cmd("edit " .. vim.fn.fnameescape(source))
  vim.notify = function(message, level)
    table.insert(notices, { message = message, level = level })
  end
  vim.env.XDG_CACHE_HOME = root .. "/cache"
  vim.env.XDG_STATE_HOME = root .. "/state"
  vim.env.XDG_DATA_HOME = root .. "/data"
  vim.go.loadplugins = true
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  vim.opt.runtimepath:prepend(plugin_root .. "/lazy.nvim")
  local overseer_spec = dofile("lua/plugins/overseer.lua")[2]
  overseer_spec.dir = plugin_root .. "/overseer.nvim"
  overseer_spec.dependencies = nil -- No optional UI integrations needed for this isolated test.
  require("lazy").setup({
    spec = { overseer_spec, dofile("lua/plugins/codescene.lua")[1] },
    defaults = { lazy = true },
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
  test("lazy startup does not load CodeScene or execute the CLI", function()
    assert(not package.loaded["config.codescene"])
    assert(not require("lazy.core.config").plugins["overseer.nvim"]._.loaded)
    assert(vim.fn.filereadable(root .. "/called.json") == 0)
  end)
  test("CodeScene lazy command merges existing Overseer options and handles absent CLI", function()
    vim.env.PATH = root .. "/empty"
    vim.cmd("CodeScene")
    assert(require("lazy.core.config").plugins["overseer.nvim"]._.loaded)
    assert(require("overseer.config").dap == false)
    assert(require("overseer.config").task_win.border == "single")
    assert(#require("overseer").list_tasks() == 0)
    assert(notices[#notices].message:find("not on PATH", 1, true))
    vim.env.PATH = root .. "/bin:" .. original_path
  end)

  local codescene = require("config.codescene")
  local overseer = require("overseer")
  local function launch(mode, scope)
    vim.fn.writefile({ mode }, root .. "/mode")
    -- Opening output must not change the buffer used by the next command.
    assert(vim.api.nvim_buf_get_name(0) == source)
    local task = assert(codescene.run(scope))
    table.insert(tasks, task)
    return task
  end
  local function finish(task, expected)
    assert(
      vim.wait(5000, function()
        return task:is_complete()
      end, 10),
      "Task did not finish"
    )
    assert(task.status == expected, "Expected " .. expected .. ", got " .. task.status)
    return table.concat(vim.api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, false), "\n")
  end

  local function output_window(task)
    assert(vim.api.nvim_buf_get_name(0) == source, "Output must not take source focus")
    local windows = vim.fn.win_findbuf(task:get_bufnr())
    assert(#windows > 0, "The new task's full output must be displayed, not only retained in a buffer")
    return windows[1]
  end

  test("multiline authentication guidance opens even with an existing side task list", function()
    overseer.open({ direction = "left", enter = false })
    local task = launch("auth", "file")
    local output = finish(task, "FAILURE")
    assert(output:find("Use the official CLI authentication instructions", 1, true))
    output_window(task)
    assert(#vim.fn.getqflist() == 0)
  end)
  test("successive checks display the new task and reuse the output pane", function()
    local first = launch("auth", "file")
    finish(first, "FAILURE")
    local win = output_window(first)
    local count = #vim.api.nvim_tabpage_list_wins(0)
    local second = launch("findings", "staged")
    finish(second, "SUCCESS")
    assert(output_window(second) == win, "Repeated checks should reuse the result pane")
    assert(#vim.api.nvim_tabpage_list_wins(0) == count)
  end)
  test("restarting an Overseer task keeps its replacement output pane reusable", function()
    local first = launch("clean", "file")
    finish(first, "SUCCESS")
    local win = output_window(first)
    local count = #vim.api.nvim_tabpage_list_wins(0)
    local original_buf = first:get_bufnr()
    assert(first:restart())
    finish(first, "SUCCESS")
    assert(first:get_bufnr() ~= original_buf, "Pinned Overseer replaces output buffers on restart")
    assert(output_window(first) == win)
    local second = launch("auth", "file")
    finish(second, "FAILURE")
    assert(output_window(second) == win, "A restarted task's output pane must still be reused")
    assert(#vim.api.nvim_tabpage_list_wins(0) == count)
  end)
  test("replacing or closing the output pane never overwrites an unrelated buffer", function()
    local first = launch("clean", "file")
    finish(first, "SUCCESS")
    local old_win = output_window(first)
    local unrelated = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(old_win, unrelated)
    local second = launch("clean", "file")
    finish(second, "SUCCESS")
    local new_win = output_window(second)
    assert(new_win ~= old_win and vim.api.nvim_win_get_buf(old_win) == unrelated)
    vim.api.nvim_win_close(old_win, true)
    vim.api.nvim_win_close(new_win, true)
    local third = launch("unsupported", "file")
    finish(third, "SUCCESS")
    output_window(third)
  end)

  test("a check in another tab leaves the previous tab's result pane intact", function()
    local first = launch("clean", "file")
    finish(first, "SUCCESS")
    local first_win = output_window(first)
    local first_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd.tabnew()
    vim.cmd("edit " .. vim.fn.fnameescape(source))
    local second_tab = vim.api.nvim_get_current_tabpage()
    local second = launch("auth", "file")
    finish(second, "FAILURE")
    local second_win = output_window(second)
    assert(vim.api.nvim_win_get_tabpage(second_win) == second_tab)
    assert(vim.api.nvim_win_get_buf(first_win) == first:get_bufnr())
    vim.cmd.tabclose()
    assert(vim.api.nvim_get_current_tabpage() == first_tab)
    assert(vim.api.nvim_win_get_buf(first_win) == first:get_bufnr())
  end)

  test("official file format becomes quickfix while argv, stderr and project root are preserved", function()
    local task = launch("findings", "file")
    local output = finish(task, "SUCCESS")
    assert(output:find("Raw stderr remains visible", 1, true))
    local called = vim.json.decode(table.concat(vim.fn.readfile(root .. "/called.json"), "\n"))
    assert(vim.deep_equal({ "check", source }, called.args))
    assert(called.cwd == root)
    local items = vim.fn.getqflist()
    assert(#items == 2, vim.inspect(items))
    assert(items[1].lnum == 2 and items[1].type == "W")
    assert(items[2].lnum == 1 and items[2].type == "I")
    assert(vim.api.nvim_buf_get_name(items[1].bufnr) == source)
    assert(#vim.diagnostic.get(0) == 0, "No LSP/inline diagnostics should be published")
  end)
  test("nonzero findings stay FAILURE with clickable entries and full output", function()
    local task = launch("findings-nonzero", "file")
    assert(finish(task, "FAILURE"):find("Complex Method", 1, true))
    assert(#vim.fn.getqflist() == 2)
  end)
  test("authentication and command errors remain failures, never false clean reports", function()
    for mode, text in pairs({ auth = "Authentication required", error = "Unknown CLI option" }) do
      assert(finish(launch(mode, "file"), "FAILURE"):find(text, 1, true))
      assert(#vim.fn.getqflist() == 0, "Old findings must not remain in the active quickfix list")
    end
  end)
  test("unmatched/unsupported and clean output remain visible with no fabricated diagnostics", function()
    for mode, text in pairs({ unsupported = "Unsupported language", clean = "No Code Health issues" }) do
      assert(finish(launch(mode, "file"), "SUCCESS"):find(text, 1, true))
      assert(#vim.fn.getqflist() == 0)
    end
  end)
  test("delta and staged use raw output and do not claim exit zero means no findings", function()
    for _, scope in ipairs({ "delta", "staged" }) do
      assert(finish(launch("findings", scope), "SUCCESS"):find("Complex Method", 1, true))
      local called = vim.json.decode(table.concat(vim.fn.readfile(root .. "/called.json"), "\n"))
      assert(vim.deep_equal(scope == "delta" and { "delta" } or { "delta", "--staged" }, called.args))
    end
  end)
  test("manual cancellation stops a running check", function()
    local task = launch("hang", "delta")
    assert(task:is_running())
    assert(task:stop())
    assert(task.status == "CANCELED")
    assert(task.strategy.job_id == nil)
  end)
  test("timeout cancels rather than passes a stalled check", function()
    vim.g.codescene_timeout = 1
    local task = launch("hang", "file")
    finish(task, "CANCELED")
    assert(task.strategy.job_id == nil)
    vim.g.codescene_timeout = nil
  end)
  test("a command disappearing after preflight is disposed rather than left pending", function()
    local original_definition = codescene.definition
    codescene.definition = function(scope)
      local definition = assert(original_definition(scope))
      definition.cmd[1] = root .. "/missing-executable"
      return definition
    end
    local before = #overseer.list_tasks()
    assert(codescene.run("file") == nil)
    assert(#overseer.list_tasks() == before)
    assert(notices[#notices].message:find("could not start", 1, true))
    codescene.definition = original_definition
  end)
end

local ok, err = xpcall(run, debug.traceback)
for _, task in ipairs(tasks) do
  task:stop()
  task:dispose(true)
end
vim.notify = original_notify
vim.env.PATH = original_path
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print(("%d pinned-plugin CodeScene integration checks passed"):format(passed))
