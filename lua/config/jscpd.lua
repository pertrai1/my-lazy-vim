-- Copy/paste detection via jscpd, with results in the quickfix list.
--
-- SonarQube computes duplication server-side only -- its analyzer ships
-- `NoOpNewCpdTokens`, the same no-op pattern it uses for coverage -- so
-- duplication can never surface through the language server. jscpd fills that
-- gap locally.
--
--   <leader>cu   scan code (any language; prose and config excluded)
--   <leader>cU   scan everything, including markdown, yaml and json
--
-- Results land in the quickfix list, so ]q / [q walk between duplicate blocks.
local M = {}

-- Build/vendor/output directories across ecosystems. These are not "this
-- repo's" directories -- the point is that one keymap works in any project.
local IGNORE = {
  "**/.git/**",
  "**/node_modules/**", -- node
  "**/vendor/**", -- go, php
  "**/target/**", -- rust, maven
  "**/build/**",
  "**/dist/**",
  "**/out/**",
  "**/bin/**",
  "**/obj/**", -- dotnet
  "**/.venv/**",
  "**/venv/**",
  "**/__pycache__/**", -- python
  "**/.next/**",
  "**/.nuxt/**",
  "**/.svelte-kit/**",
  "**/coverage/**",
  "**/report/**", -- our own tooling output
  "**/.terraform/**",
  "**/Pods/**", -- swift/objc
  -- Vendored and generated code: real duplication, but not yours to fix.
  "**/third_party/**",
  "**/third-party/**",
  "**/external/**",
  "**/*.min.js",
  "**/*.min.css",
  "**/*.bundle.js",
  "**/*.generated.*",
  "**/*_pb2.py", -- protobuf
  "**/*.pb.go",
}

-- Prose and config formats. jscpd happily reports duplicated markdown and
-- boilerplate CI yaml, which buries real code findings. Excluded by extension
-- rather than by allow-listing languages, so the default scan stays correct
-- for any language without needing to enumerate them.
local NON_CODE = {
  "**/*.md",
  "**/*.mdx",
  "**/*.markdown",
  "**/*.txt",
  "**/*.rst",
  "**/*.adoc",
  "**/*.json",
  "**/*.jsonc",
  "**/*.yml",
  "**/*.yaml",
  "**/*.toml",
  "**/*.ini",
  "**/*.cfg",
  "**/*.lock",
  "**/*.csv",
  "**/*.svg",
  "**/*.html",
  "**/*.snap",
}

local function notify(msg, level)
  vim.notify("jscpd: " .. msg, level or vim.log.levels.INFO)
end

-- Projects can override every default by committing .jscpd.json at the root.
local function project_config(root)
  local path = vim.fs.joinpath(root, ".jscpd.json")
  return vim.fn.filereadable(path) == 1 and path or nil
end

local function repo_root()
  local name = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(name ~= "" and name or vim.fn.getcwd(), { ".git" }) or vim.fn.getcwd()
end

-- Prefer a project-local install; fall back to npx so this works in any repo
-- without installing anything.
local function command(root)
  local local_bin = vim.fs.joinpath(root, "node_modules", ".bin", "jscpd")
  if vim.fn.executable(local_bin) == 1 then
    return { local_bin }
  end
  if vim.fn.executable("jscpd") == 1 then
    return { "jscpd" }
  end
  return { "npx", "--yes", "jscpd@5" }
end

-- jscpd's xcode reporter emits either
--   path/to/file.ts:12:4: warning: msg
-- or, for files tokenised per embedded block (markdown containing typescript,
-- text, ...), an extra format segment:
--   docs/TESTING.md:typescript:97:0: warning: msg
-- The segment is indistinguishable from a path component by shape, so resolve
-- the ambiguity against the filesystem rather than by guessing.
local function parse(line, root)
  local head, lnum, col, msg = line:match("^(.+):(%d+):(%d+): warning: (.+)$")
  if not head then
    return nil
  end

  local function readable(rel)
    return vim.fn.filereadable(vim.fs.joinpath(root, rel)) == 1
  end

  local file = head
  if not readable(file) then
    local without_format = head:match("^(.+):[^:]+$")
    if without_format and readable(without_format) then
      file = without_format
    end
  end

  return {
    filename = vim.fs.joinpath(root, file),
    lnum = tonumber(lnum),
    -- jscpd reports 0-based columns; quickfix expects 1-based.
    col = tonumber(col) + 1,
    text = msg,
    type = "W",
  }
end

--- @param opts? { all?: boolean, min_tokens?: integer }
function M.run(opts)
  opts = opts or {}
  local root = repo_root()

  local cmd = command(root)
  vim.list_extend(cmd, { ".", "--reporters", "xcode" })

  -- A project that ships .jscpd.json has already decided what to scan --
  -- every vendored directory is project-specific, and no built-in list can
  -- know them. jscpd auto-discovers the file, so passing our own --ignore
  -- would silently override the project's intent. Defer to it entirely.
  if project_config(root) then
    if opts.min_tokens then
      vim.list_extend(cmd, { "--min-tokens", tostring(opts.min_tokens) })
    end
  else
    local ignore = vim.list_slice(IGNORE)
    if not opts.all then
      vim.list_extend(ignore, NON_CODE)
    end
    vim.list_extend(cmd, {
      "--min-tokens",
      tostring(opts.min_tokens or 50),
      "--ignore",
      table.concat(ignore, ","),
    })
  end

  notify(
    ("scanning %s%s%s..."):format(
      vim.fn.fnamemodify(root, ":~"),
      opts.all and " (all formats)" or "",
      project_config(root) and " [.jscpd.json]" or ""
    )
  )

  vim.system(cmd, { cwd = root, text = true }, function(res)
    vim.schedule(function()
      local items = {}
      for line in (res.stdout or ""):gmatch("[^\r\n]+") do
        local item = parse(line, root)
        if item then
          table.insert(items, item)
        end
      end

      if #items == 0 then
        -- A non-zero exit with no parsed findings means jscpd itself failed;
        -- surface its stderr instead of reporting a clean scan.
        if res.code ~= 0 then
          notify("failed: " .. vim.trim((res.stderr or ""):sub(1, 400)), vim.log.levels.ERROR)
        else
          notify("no duplicates found")
        end
        return
      end

      vim.fn.setqflist({}, " ", { title = "jscpd duplicates", items = items })
      vim.cmd("copen")
      notify(("%d duplicate blocks -- ]q / [q to navigate"):format(#items))
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Jscpd", function(cmd)
    M.run({ all = false, min_tokens = tonumber(cmd.args) })
  end, { nargs = "?", desc = "Find duplicate code (source formats)" })

  vim.api.nvim_create_user_command("JscpdAll", function(cmd)
    M.run({ all = true, min_tokens = tonumber(cmd.args) })
  end, { nargs = "?", desc = "Find duplicate code (all formats)" })

  local map = vim.keymap.set
  map("n", "<leader>cu", function()
    M.run()
  end, { desc = "Find duplicate code" })
  map("n", "<leader>cU", function()
    M.run({ all = true })
  end, { desc = "Find duplicate code (all formats)" })
end

return M
