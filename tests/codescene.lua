-- nvim --headless -u NONE -l tests/codescene.lua
-- No real CodeScene invocation, plugins, credentials, or network required.
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local codescene = require("config.codescene")
local root = vim.fn.tempname() .. " project with spaces"
local original_path = vim.env.PATH
local original_cwd = vim.fn.getcwd()
local passed = 0

local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), ("expected %s, got %s"):format(vim.inspect(expected), vim.inspect(actual)))
end

local function test(name, callback)
  callback()
  passed = passed + 1
  print("ok - " .. name)
end

local function file(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ "const value = 1;" }, path)
  return path
end

local function edit(path)
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  vim.bo.filetype = ""
end

local function rejected(scope, pattern)
  local definition, message = codescene.definition(scope)
  equal(nil, definition)
  assert(message:find(pattern, 1, true), message)
end

local function git(...)
  local result = vim.system({ "git", "-C", root, ... }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end

local function run()
  vim.fn.mkdir(root .. "/bin", "p")
  local cli = root .. "/bin/cs"
  vim.fn.writefile({ "#!/bin/sh", "exit 99" }, cli)
  assert(vim.fn.setfperm(cli, "rwx------") == 1)
  vim.env.PATH = root .. "/bin:" .. original_path
  git("init", "--quiet")
  local source = file(root .. "/nested package/-sample ; $name.ts")
  file(root .. "/nested package/package.json")
  edit(source)

  test("file check uses argv and Git root rather than a nested package or editor cwd", function()
    local definition = assert(codescene.definition())
    equal({ cli, "check", source }, definition.cmd)
    equal(root, definition.cwd)
    equal("file", definition.metadata.scope)
    equal({ "jobstart", use_terminal = false }, definition.strategy)
    equal(300, definition.components[2].timeout)
    equal("%tnfo: %f:%l: %m,%tarn: %f:%l: %m", definition.components[3].errorformat)
    equal(false, definition.components[3].set_diagnostics)
    equal(false, definition.components[3].tail)
    equal(codescene.definition("file"), codescene.definition(""))
  end)

  test("changed and staged checks remain manual and separate from validation", function()
    equal({ cli, "delta" }, codescene.definition("delta").cmd)
    equal({ cli, "delta", "--staged" }, codescene.definition("staged").cmd)
    equal(2, #codescene.definition("delta").components)
    equal({}, require("config.validation_tasks").templates(root))
  end)

  test("missing CLI and invalid scope report actionable errors", function()
    vim.env.PATH = root .. "/empty"
    rejected("file", "not on PATH")
    vim.env.PATH = root .. "/bin:" .. original_path
    rejected("unknown", "Use :CodeScene")
  end)

  test("file checks require saved, unmodified normal buffers", function()
    vim.bo.modified = true
    rejected("file", "Save the current buffer")
    rejected("delta", "Save modified buffers")
    assert(codescene.definition("staged"), "Staged checks must use the index even with unsaved edits")
    vim.bo.modified = false
    edit(root .. "/not saved.ts")
    rejected("file", "saved, readable")
    vim.cmd("enew!")
    rejected("file", "saved, readable")
    vim.api.nvim_buf_set_name(0, "terminal://not-a-project")
    vim.bo.buftype = "nofile"
    rejected("file", "saved, readable")
    vim.cmd("cd " .. vim.fn.fnameescape(root))
    equal(root, codescene.definition("delta").cwd)
    edit(source)
  end)

  test("unsaved noncurrent buffers in the repository block delta but unrelated ones do not", function()
    local other = vim.fn.bufadd(file(root .. "/other.js"))
    vim.fn.bufload(other)
    vim.bo[other].modified = true
    rejected("delta", "Save modified buffers")
    vim.bo[other].modified = false
    local outside = vim.fn.bufadd(file(root .. "-outside/other.js"))
    vim.fn.bufload(outside)
    vim.bo[outside].modified = true
    assert(codescene.definition("delta"))
    vim.bo[outside].modified = false
  end)

  test("unsaved buffers opened through a directory symlink also block delta", function()
    assert(vim.uv.fs_symlink(root, root .. "-link", { dir = true }))
    edit(root .. "-link/nested package/-sample ; $name.ts")
    vim.bo.modified = true
    rejected("delta", "Save modified buffers")
    vim.bo.modified = false
    edit(source)
    vim.fn.delete(root .. "-link")
  end)

  test("Lua reports unsupported rather than a misleading clean check", function()
    edit(file(root .. "/config.LUA"))
    rejected("file", "does not support Lua")
    edit(source)
    vim.bo.filetype = "lua"
    rejected("file", "does not support Lua")
    vim.bo.filetype = ""
  end)

  test("file checks work outside Git, delta and staged explain the requirement", function()
    local outside = file(root .. "-outside/standalone.cs")
    edit(outside)
    equal(vim.fs.dirname(outside), codescene.definition("file").cwd)
    rejected("delta", "Git working tree")
    rejected("staged", "Git working tree")
    edit(source)
  end)

  test("missing Git and a stalled root lookup fail gracefully", function()
    vim.env.PATH = root .. "/bin"
    rejected("delta", "Git working tree")
    equal(vim.fs.dirname(source), codescene.definition("file").cwd)
    vim.env.PATH = root .. "/bin:" .. original_path
    vim.fn.writefile({ "#!/bin/sh", "exec /bin/sleep 10" }, root .. "/bin/git")
    assert(vim.fn.setfperm(root .. "/bin/git", "rwx------") == 1)
    local start = vim.uv.hrtime()
    rejected("delta", "2 seconds")
    assert((vim.uv.hrtime() - start) / 1e9 < 5, "Git lookup was not bounded")
    vim.fn.delete(root .. "/bin/git")
  end)

  test("custom timeout is bounded and malformed settings cannot break task creation", function()
    vim.g.codescene_timeout = 30
    equal(30, codescene.definition("file").components[2].timeout)
    for _, invalid in ipairs({ 0, -1, 0.5, "300", math.huge }) do
      vim.g.codescene_timeout = invalid
      rejected("file", "positive integer")
    end
    vim.g.codescene_timeout = nil
  end)

  test("linked worktrees resolve their own Git root", function()
    git(
      "-c",
      "user.name=Fixture",
      "-c",
      "user.email=fixture@example.invalid",
      "commit",
      "--allow-empty",
      "-m",
      "fixture"
    )
    git("worktree", "add", "--detach", root .. "-worktree", "HEAD")
    edit(file(root .. "-worktree/nested/a.tsx"))
    equal(root .. "-worktree", codescene.definition("file").cwd)
    equal(root .. "-worktree", codescene.definition("delta").cwd)
    edit(source)
  end)

  test("setup is idempotent, does not execute checks, and exposes scope completion", function()
    codescene.setup()
    codescene.setup()
    equal({ "delta" }, vim.fn.getcompletion("CodeScene d", "cmdline"))
    local calls = {}
    local original_run = codescene.run
    codescene.run = function(scope)
      table.insert(calls, scope)
    end
    vim.cmd("CodeScene")
    vim.cmd("CodeScene staged")
    equal({ "", "staged" }, calls)
    codescene.run = original_run
  end)
end

local ok, err = xpcall(run, debug.traceback)
vim.env.PATH = original_path
vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
vim.fn.delete(root .. "-link")
for _, path in ipairs({ root, root .. "-outside", root .. "-worktree" }) do
  vim.fn.delete(path, "rf")
end
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print(("%d CodeScene regression checks passed"):format(passed))
