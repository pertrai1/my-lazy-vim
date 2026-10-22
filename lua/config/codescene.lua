local M = {}

local scopes = { "file", "delta", "staged" }

local function warn(message)
  vim.notify(message, vim.log.levels.WARN, { title = "CodeScene" })
end

local function git_root(dir)
  if vim.fn.executable("git") ~= 1 then
    return nil
  end
  local ok, result = pcall(function()
    return vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait(2000)
  end)
  if ok and result.code == 0 then
    return vim.fs.normalize((result.stdout:gsub("\n$", "")))
  end
end

-- New buffers may not exist yet. Resolve their closest existing ancestor so
-- missing children below a directory symlink still belong to the real root.
local function canonical_path(path)
  local original = path
  local missing = {}
  while path do
    local real = vim.uv.fs_realpath(path)
    if real then
      for i = #missing, 1, -1 do
        real = vim.fs.joinpath(real, missing[i])
      end
      return vim.fs.normalize(real)
    end
    local parent = vim.fs.dirname(path)
    if not parent or parent == path then
      break
    end
    table.insert(missing, vim.fs.basename(path))
    path = parent
  end
  return vim.fs.normalize(original)
end

local function modified_in(root)
  local prefix = canonical_path(root):gsub("/+$", "") .. "/"
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].modified then
      local name = vim.api.nvim_buf_get_name(buf)
      local path = name ~= "" and canonical_path(name) or ""
      if (name == "" and buf == vim.api.nvim_get_current_buf()) or path:sub(1, #prefix) == prefix then
        return true
      end
    end
  end
  return false
end

-- Build only on an explicit command. Never install, log in, save, or stage files.
function M.definition(scope)
  scope = (scope == nil or scope == "") and "file" or scope
  if not vim.tbl_contains(scopes, scope) then
    return nil, "Use :CodeScene file, :CodeScene delta, or :CodeScene staged"
  end
  local executable = vim.fn.exepath("cs")
  if executable == "" then
    return nil, "CodeScene CLI (cs) is not on PATH. See CODE-QUALITY.md for optional setup."
  end
  local timeout = vim.g.codescene_timeout or 300
  if type(timeout) ~= "number" or timeout <= 0 or timeout % 1 ~= 0 or timeout == math.huge then
    return nil, "vim.g.codescene_timeout must be a positive integer number of seconds"
  end

  local filename = vim.api.nvim_buf_get_name(0)
  local normal_file = vim.bo.buftype == "" and filename ~= ""
  local dir = normal_file and vim.fs.dirname(filename) or vim.fn.getcwd()
  local root = git_root(dir)
  local cmd = { executable }
  local name
  local components = { "default", { "timeout", timeout = timeout } }
  if scope == "file" then
    if not normal_file or vim.fn.filereadable(filename) ~= 1 then
      return nil, "Open a saved, readable source file before running :CodeScene file"
    end
    if vim.bo.modified then
      return nil, "Save the current buffer first; CodeScene checks the file on disk"
    end
    if filename:lower():match("%.lua$") or vim.bo.filetype == "lua" then
      return nil, "CodeScene Code Health does not support Lua. Use this check in a supported application file."
    end
    vim.list_extend(cmd, { "check", filename })
    name = "CodeScene: file " .. vim.fs.basename(filename)
    -- Official `cs docs vim` format, verified with CLI 1.0.54. Keep stderr and
    -- unmatched output in Overseer; no guessed JSON schema or inline diagnostics.
    table.insert(components, {
      "on_output_quickfix",
      errorformat = "%tnfo: %f:%l: %m,%tarn: %f:%l: %m",
      items_only = true,
      tail = false,
      set_diagnostics = false,
    })
  else
    if not root then
      return nil,
        "CodeScene delta/staged needs a Git working tree and git on PATH (root lookup is limited to 2 seconds)"
    end
    if scope == "delta" and modified_in(root) then
      return nil, "Save modified buffers in this repository first; CodeScene delta checks saved working-tree changes"
    end
    table.insert(cmd, "delta")
    if scope == "staged" then
      table.insert(cmd, "--staged")
    end
    name = "CodeScene: " .. scope
  end
  return {
    name = name,
    cmd = cmd,
    cwd = root or dir,
    -- Non-interactive, unwrapped output; argv preserves spaces/metacharacters.
    strategy = { "jobstart", use_terminal = false },
    components = components,
    metadata = { category = "codescene", scope = scope },
  }
end

-- A task list may already be open without a preview, or still select an older
-- task. Show this exact output independently, reusing only our own result pane.
local function open_output(task)
  local bufnr = task:get_bufnr()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local existing = vim.api.nvim_win_get_buf(win)
    local previous = vim.w[win].codescene_task_id
    -- Overseer replaces output buffers on restart but preserves the task ID.
    if previous and vim.b[existing].overseer_task == previous then
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.w[win].codescene_task_id = task.id
      return
    end
  end
  local current = vim.api.nvim_get_current_win()
  task:open_output("horizontal")
  vim.w.codescene_task_id = task.id
  vim.api.nvim_set_current_win(current)
end

function M.run(scope)
  local definition, error = M.definition(scope)
  if not definition then
    warn(error)
    return
  end
  local overseer = require("overseer")
  local task = overseer.new_task(definition)
  if not task:start() then
    task:dispose(true)
    warn("The CLI could not start. Check that cs is executable and the project directory still exists.")
    return
  end
  open_output(task)
  return task
end

function M.setup()
  vim.api.nvim_create_user_command("CodeScene", function(opts)
    M.run(opts.args)
  end, {
    nargs = "?",
    desc = "Run an optional, manual CodeScene file/delta/staged check",
    complete = function(lead)
      return vim.tbl_filter(function(scope)
        return scope:sub(1, #lead) == lead
      end, scopes)
    end,
  })
end

return M
