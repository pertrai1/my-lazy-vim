-- SonarQube for IDE (SonarLint) via the sonarlint-language-server, with
-- per-repository Connected Mode so local analysis follows whichever server a
-- given repo belongs to.
--
-- Connected Mode is split into two pieces so credentials never live inside a
-- project repo:
--
--   1. Connections (secret) -- one file, outside every repo:
--        ~/.local/share/nvim/sonarqube/connections.json     (chmod 600)
--
--        {
--          "work": {
--            "serverUrl": "https://sonarqube.corp.example.com",
--            "tokenCmd": ["security", "find-generic-password", "-w", "-s", "sonar-work"]
--          },
--          "cloud": {
--            "organizationKey": "my-org",
--            "tokenCmd": ["security", "find-generic-password", "-w", "-s", "sonar-cloud"]
--          }
--        }
--
--      Each entry names exactly one of:
--        serverUrl       -- self-hosted SonarQube Server
--        organizationKey -- SonarQube Cloud (formerly SonarCloud); add
--                           "region": "US" for sonarqube.us, default is EU
--
--      ...plus exactly one of:
--        token     -- literal token (simplest, but plaintext on disk)
--        tokenCmd  -- argv printing the token (keychain, pass, 1Password CLI)
--        tokenEnv  -- name of an env var holding the token
--
--   2. Binding (no secrets) -- per repository, at the repo root:
--        .sonarlint.json
--        { "connection": "work", "projectKey": "my-service" }
--
--      This only *names* a connection, so it is safe to commit. Repos on
--      different servers name different connections; repos sharing a server
--      name the same one.
--
-- Setup:
--   1. :SonarQubeInstallLsp                 -- language server + analyzer jars
--   2. Generate a token per server: My Account > Security
--   3. Write connections.json (see :SonarQubeConnectedStatus for the path)
--   4. Drop a .sonarlint.json in each repo you want bound
--
-- Without a resolvable binding, SonarQube for IDE still runs standalone
-- (default rules, no server sync) -- Connected Mode just doesn't activate.
--
-- Check the result at any time with :SonarQubeConnectedStatus.

local CONNECTIONS_FILE = vim.fs.joinpath(vim.fn.stdpath("data"), "sonarqube", "connections.json")
local BINDING_FILE = ".sonarlint.json"

-- Environment variables are still honoured, but only as a fallback when the
-- repo has no .sonarlint.json -- handy for one-off checkouts and CI.
local ENV = { url = "SONARQUBE_URL", token = "SONARQUBE_TOKEN", project = "SONARQUBE_PROJECT_KEY" }

local M = {}

-- Sonar ships its own severity on each diagnostic, in `data.impactSeverity`,
-- as a raw enum ordinal (DiagnosticPublisher calls .ordinal() on it). LSP only
-- has 4 severities, so every Sonar issue arrives as plain WARN and the real
-- grade is invisible until you decode this.
--
-- Two enums share the ordinal range, and which one is sent depends on the
-- server's mode -- the integer alone cannot tell them apart:
--   MQR mode      INFO LOW    MEDIUM HIGH     BLOCKER   (SonarQube Cloud default)
--   Standard mode INFO MINOR  MAJOR  CRITICAL BLOCKER
-- Set this to "standard" if your server still runs the older severity model.
local SEVERITY_MODE = "mqr"

local SEVERITY_LABELS = {
  mqr = { [0] = "INFO", [1] = "LOW", [2] = "MEDIUM", [3] = "HIGH", [4] = "BLOCKER" },
  standard = { [0] = "INFO", [1] = "MINOR", [2] = "MAJOR", [3] = "CRITICAL", [4] = "BLOCKER" },
}

-- Raise the two most serious grades to ERROR so they read as red rather than
-- sitting at the same WARN as a style nit. Deliberately only promotes: nothing
-- is demoted, so no issue can become filtered out or invisible.
local PROMOTE_SEVERE = true

-- Decorate Sonar diagnostics in place with their real severity.
local function decorate(diagnostics)
  local labels = SEVERITY_LABELS[SEVERITY_MODE] or SEVERITY_LABELS.mqr

  for _, d in ipairs(diagnostics or {}) do
    local ordinal = type(d.data) == "table" and d.data.impactSeverity or nil
    local label = ordinal and labels[ordinal]
    if label then
      d.message = ("[%s] %s"):format(label, d.message)
      if PROMOTE_SEVERE and ordinal >= 3 then
        d.severity = vim.diagnostic.severity.ERROR
      end
    end
  end
end

-- The language server publishes security findings on two channels separate
-- from textDocument/publishDiagnostics, and sonarqube.nvim handles neither:
--
--   sonarlint/publishSecurityHotspots      -- security hotspots to review
--   sonarlint/publishTaintVulnerabilities  -- injection flaws computed
--                                             server-side, Connected Mode only
--
-- Both carry PublishDiagnosticsParams. Unhandled, anything they send is
-- dropped silently. They are frequently empty -- taint analysis in particular
-- depends on the server edition -- but when they are not, these are the most
-- serious findings Sonar produces, so they must not be discarded.
local EXTRA_CHANNELS = {
  ["sonarlint/publishSecurityHotspots"] = { ns = "sonarqube/hotspots", source = "sonarqube-hotspot" },
  ["sonarlint/publishTaintVulnerabilities"] = { ns = "sonarqube/taint", source = "sonarqube-taint" },
}

local namespaces = {}
local function namespace(name)
  namespaces[name] = namespaces[name] or vim.api.nvim_create_namespace(name)
  return namespaces[name]
end

-- LSP -> vim.diagnostic. Hand-rolled because vim.lsp.diagnostic.from converts
-- the other direction, and the stock publish handler would reuse the client's
-- own namespace, letting these overwrite the regular diagnostics.
local function to_vim_diagnostic(d, source)
  local start, finish = d.range.start, d.range["end"]
  return {
    lnum = start.line,
    col = start.character,
    end_lnum = finish.line,
    end_col = finish.character,
    severity = d.severity or vim.diagnostic.severity.WARN,
    message = d.message,
    -- Distinct source so these are visibly not ordinary code smells; inline
    -- diagnostics render it alongside the message.
    source = source,
    code = d.code,
    user_data = { lsp = d },
  }
end

local function warn(msg)
  vim.notify("sonarqube: " .. msg, vim.log.levels.WARN)
end

-- Existing on disk is not the same as working: macOS ships a /usr/bin/java stub
-- that is present and executable but exits non-zero with "Unable to locate a
-- Java Runtime". exepath() finds it, the plugin uses it, and the client dies as
-- "quit with exit code 1" with no hint of why. Only a successful run proves it.
local function java_works(path)
  if not path or path == "" then
    return false
  end
  local ok, res = pcall(function()
    return vim.system({ path, "-version" }, { text = true }):wait()
  end)
  return ok and res.code == 0
end

-- Homebrew's openjdk formula is keg-only and JDKs installed as macOS packages
-- live outside PATH entirely, so a perfectly good JDK routinely isn't visible
-- to exepath(). Look in the standard locations before giving up.
local function find_java()
  local patterns = {
    "/opt/homebrew/opt/openjdk*/bin/java", -- brew, Apple Silicon
    "/usr/local/opt/openjdk*/bin/java", -- brew, Intel
    "/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java", -- temurin & co
    vim.fn.expand("~/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java"),
  }

  local found = {}
  for _, pattern in ipairs(patterns) do
    vim.list_extend(found, vim.fn.glob(pattern, false, true))
  end

  -- Newest version first, so jdk-21 wins over jdk-17 when both are present.
  table.sort(found, function(a, b)
    return a > b
  end)

  for _, candidate in ipairs(found) do
    if java_works(candidate) then
      return candidate
    end
  end
end

function M.java_ok()
  if java_works(vim.fn.exepath("java")) then
    return true
  end

  -- Put the discovered JDK on PATH before the plugin's config module runs, so
  -- its `vim.fn.exepath("java")` default picks this one up.
  local java = find_java()
  if java then
    vim.env.PATH = vim.fs.dirname(java) .. ":" .. vim.env.PATH
    return true
  end

  warn("no working JDK found -- the language server is a JVM process and cannot start")
  warn("install one with: brew install --cask temurin@21")
  return false
end

local function read_json(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" then
    warn(("could not parse %s: %s"):format(path, decoded))
    return nil
  end
  return decoded
end

-- The repo a buffer belongs to. `.git` matches the language server's own root
-- detection, so the binding we resolve lines up with the workspace it analyses.
local function repo_root(bufnr)
  local name = bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or ""
  local start = name ~= "" and name or vim.fn.getcwd()
  return vim.fs.root(start, { ".git" })
end

local function resolve_token(name, conn)
  if conn.token and conn.token ~= "" then
    return conn.token
  end

  if conn.tokenEnv then
    local token = os.getenv(conn.tokenEnv)
    if not token or token == "" then
      warn(("connection %q: $%s is unset"):format(name, conn.tokenEnv))
    end
    return token
  end

  if conn.tokenCmd then
    local cmd = type(conn.tokenCmd) == "table" and conn.tokenCmd or { conn.tokenCmd }
    local res = vim.system(cmd, { text = true }):wait()
    if res.code ~= 0 then
      warn(("connection %q: tokenCmd failed (%d): %s"):format(name, res.code, vim.trim(res.stderr or "")))
      return nil
    end
    local token = vim.trim(res.stdout or "")
    if token == "" then
      warn(("connection %q: tokenCmd printed nothing"):format(name))
      return nil
    end
    return token
  end

  warn(("connection %q: needs one of token, tokenCmd, tokenEnv"):format(name))
  return nil
end

-- Returns `binding, source` where binding is { connectionId, serverUrl, token,
-- projectKey }, or nil when this repo has no usable Connected Mode config.
local function resolve_binding(root)
  if root then
    local bound = read_json(vim.fs.joinpath(root, BINDING_FILE))
    if bound then
      local name = bound.connection or bound.connectionId
      if not name or not bound.projectKey then
        warn(("%s/%s: needs both \"connection\" and \"projectKey\""):format(root, BINDING_FILE))
        return nil
      end

      local connections = read_json(CONNECTIONS_FILE)
      local conn = connections and connections[name]
      if not conn then
        warn(("%s/%s names connection %q, which is not in %s"):format(root, BINDING_FILE, name, CONNECTIONS_FILE))
        return nil
      end

      -- serverUrl -> SonarQube Server, organizationKey -> SonarQube Cloud.
      -- The language server keys these under different settings blocks.
      local kind
      if conn.serverUrl and conn.organizationKey then
        warn(("connection %q: set serverUrl or organizationKey, not both"):format(name))
        return nil
      elseif conn.organizationKey then
        kind = "sonarcloud"
      elseif conn.serverUrl then
        kind = "sonarqube"
      else
        warn(("connection %q: needs serverUrl (Server) or organizationKey (Cloud)"):format(name))
        return nil
      end

      local token = resolve_token(name, conn)
      if not token then
        return nil
      end

      return {
        kind = kind,
        connectionId = name,
        serverUrl = conn.serverUrl,
        organizationKey = conn.organizationKey,
        region = conn.region,
        token = token,
        projectKey = bound.projectKey,
      }, BINDING_FILE
    end
  end

  local url, token, project = os.getenv(ENV.url), os.getenv(ENV.token), os.getenv(ENV.project)
  if url and token and project then
    return {
      kind = "sonarqube",
      connectionId = "env",
      serverUrl = url,
      token = token,
      projectKey = project,
    }, "environment"
  end

  return nil
end

local function build_settings(binding)
  local connection = { connectionId = binding.connectionId, token = binding.token }
  if binding.kind == "sonarcloud" then
    connection.organizationKey = binding.organizationKey
    connection.region = binding.region -- nil means EU (sonarcloud.io)
  else
    connection.serverUrl = binding.serverUrl
  end

  return {
    sonarlint = {
      connectedMode = {
        connections = { [binding.kind] = { connection } },
        project = { connectionId = binding.connectionId, projectKey = binding.projectKey },
      },
    },
  }
end

-- The plugin never forwards `setup{ lsp = { settings = ... } }` into
-- vim.lsp.start -- it passes its own `sonarqube.lsp.server.settings` table
-- instead (see lua/sonarqube/lsp/init.lua). So Connected Mode has to be
-- written straight onto that module. It is picked up twice: as the client's
-- initial settings, and again by the plugin's on_attach, which pushes the same
-- table via workspace/didChangeConfiguration.
function M.apply(bufnr)
  local root = repo_root(bufnr)
  local binding, source = resolve_binding(root)

  M.state = { root = root, binding = binding, source = source }

  local server = require("sonarqube.lsp.server")
  if binding then
    server.settings = vim.tbl_deep_extend("force", server.settings or {}, build_settings(binding))

    -- Putting the token in settings is not enough. Before it will bind a
    -- project, the server asks the client for the credential over
    -- `sonarlint/getTokenForServer`, passing the serverUrl (Server) or the
    -- organizationKey (Cloud) and expecting the token back. The plugin has no
    -- handler for it, so the request goes unanswered and binding stalls with
    -- only the plugin cache synced -- no rules, no server issues.
    server.register_handler("sonarlint/getTokenForServer", function(_, params)
      -- lsp4j sends the lone String parameter; tolerate a wrapped form too.
      local asked = params
      if type(params) == "table" then
        asked = params[1] or params.serverUrlOrOrganization or params.serverUrl or params.organizationKey
      end

      -- Cloud identifies a connection as "<REGION>_<organizationKey>"
      -- (e.g. "EU_my-org"), not by the bare organization key.
      local expected = {
        binding.serverUrl,
        binding.organizationKey,
        binding.organizationKey and ((binding.region or "EU") .. "_" .. binding.organizationKey) or nil,
      }
      if asked ~= nil and not vim.tbl_contains(expected, asked) then
        -- Still answer: this session has exactly one connection, and the
        -- server only asks about connections we declared. Warn so an
        -- unrecognised identifier format is visible rather than silent.
        warn(("unexpected token request for %q -- answering with the bound token"):format(tostring(asked)))
      end

      -- Must always return a result. Returning nil leaves the request
      -- unanswered and the server waits forever, stalling project binding.
      return binding.token
    end)
  end

  -- Sonar's own severity only exists in each diagnostic's `data`, so decorate
  -- them as they arrive, then hand off to the stock handler. Registered
  -- unconditionally: severities are published in standalone mode too.
  server.register_handler("textDocument/publishDiagnostics", function(err, result, ctx, cfg)
    if result then
      decorate(result.diagnostics)
    end
    return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, cfg)
  end)

  for method, channel in pairs(EXTRA_CHANNELS) do
    server.register_handler(method, function(_, result)
      if not result or not result.uri then
        return
      end

      local bufnr = vim.uri_to_bufnr(result.uri)
      -- uri_to_bufnr creates a buffer if none exists; only publish to buffers
      -- actually open, otherwise every analysed file spawns an empty one.
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
      end

      local diagnostics = result.diagnostics or {}
      decorate(diagnostics)

      local items = {}
      for _, d in ipairs(diagnostics) do
        table.insert(items, to_vim_diagnostic(d, channel.source))
      end

      -- Setting an empty list clears the namespace, which is how the server
      -- retracts findings that no longer apply.
      vim.diagnostic.set(namespace(channel.ns), bufnr, items)
    end)
  end

  return binding
end

-- Only one sonarqube client ever runs: the plugin attaches every matching
-- buffer to the first one it started. Editing two differently-bound repos in a
-- single nvim means the second silently analyses against the first repo's
-- project, so say so rather than reporting stale issues.
function M.warn_on_foreign_repo(bufnr)
  local state = M.state
  if not state or not state.binding then
    return
  end

  local root = repo_root(bufnr)
  if not root or root == state.root then
    return
  end

  local other = resolve_binding(root)
  if other and other.projectKey ~= state.binding.projectKey then
    warn(
      ("%s is bound to %s, but this session is connected as %s; open it in its own nvim for accurate analysis"):format(
        vim.fn.fnamemodify(root, ":~"),
        other.projectKey,
        state.binding.projectKey
      )
    )
  end
end

function M.status()
  local state = M.state
  local lines = { "SonarQube Connected Mode", "" }

  table.insert(lines, "connections file : " .. CONNECTIONS_FILE)
  table.insert(lines, "                   " .. (vim.fn.filereadable(CONNECTIONS_FILE) == 1 and "found" or "MISSING"))
  table.insert(lines, "repo root        : " .. ((state and state.root) or "(not resolved)"))

  if state and state.binding then
    table.insert(lines, "status           : connected (via " .. state.source .. ")")
    table.insert(lines, "connection       : " .. state.binding.connectionId)
    if state.binding.kind == "sonarcloud" then
      table.insert(lines, "cloud org        : " .. state.binding.organizationKey)
      table.insert(lines, "region           : " .. (state.binding.region or "EU (default)"))
    else
      table.insert(lines, "server           : " .. state.binding.serverUrl)
    end
    table.insert(lines, "project          : " .. state.binding.projectKey)
    table.insert(lines, "token            : resolved (" .. #state.binding.token .. " chars, not shown)")
  else
    table.insert(lines, "status           : standalone (default rules, no server sync)")
    table.insert(lines, "")
    -- Distinguish "never configured" from "configured but failing", otherwise
    -- a bad token reads as a missing binding file.
    local has_binding = state and state.root and vim.fn.filereadable(vim.fs.joinpath(state.root, BINDING_FILE)) == 1
    if has_binding then
      table.insert(lines, BINDING_FILE .. " is present but did not resolve.")
      table.insert(lines, "Re-check the warning shown at startup (:messages) -- usually an")
      table.insert(lines, "unknown connection name or a token that could not be fetched.")
    else
      table.insert(lines, "Add " .. BINDING_FILE .. " to the repo root:")
      table.insert(lines, '  { "connection": "work", "projectKey": "my-service" }')
    end
  end

  -- Everything above only proves the *config* resolved. These lines prove the
  -- server actually started and is holding the connected-mode settings.
  table.insert(lines, "")
  table.insert(lines, "-- runtime --")

  local java = vim.fn.exepath("java")
  table.insert(lines, "java             : " .. (java ~= "" and java or "(not on PATH)"))

  local client = vim.lsp.get_clients({ name = "sonarqube" })[1]
  if not client then
    table.insert(lines, "lsp client       : NOT RUNNING")
    table.insert(lines, "                   open a js/ts/python/html file in this repo to start it")
  else
    table.insert(lines, "lsp client       : running (id " .. client.id .. ")")
    table.insert(lines, "client root      : " .. tostring(client.config.root_dir))

    local sent = vim.tbl_get(client.settings or {}, "sonarlint", "connectedMode", "project", "projectKey")
    table.insert(lines, "settings sent    : " .. (sent and ("connectedMode -> " .. sent) or "NONE (standalone)"))

    local n = #vim.tbl_filter(function(d)
      return d.source == "sonarqube"
    end, vim.diagnostic.get(0))
    table.insert(lines, "diagnostics here : " .. n .. " from sonarqube in this buffer")
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return {
  -- Register a which-key group so the commands below are discoverable.
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cQ", group = "SonarQube", icon = " " },
      },
    },
  },

  {
    "iamkarasik/sonarqube.nvim",
    ft = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "python",
      "html",
    },
    -- Without these, the commands only exist once an ft/keys trigger has
    -- already loaded the plugin -- so typing :SonarQubeConnectedStatus from,
    -- say, a README would fail with E492.
    cmd = { "SonarQubeConnectedStatus", "SonarQubeInstallLsp" },
    keys = {
      { "<leader>cQi", "<cmd>SonarQubeInstallLsp<cr>", desc = "Install SonarQube LSP" },
      { "<leader>cQc", "<cmd>SonarQubeConnectedStatus<cr>", desc = "SonarQube connected status" },
      { "<leader>cQr", "<cmd>SonarQubeListAllRules<cr>", desc = "List SonarQube rules" },
    },
    config = function()
      -- Resolve against the buffer that triggered the ft load; lazy.nvim fires
      -- FileType again after loading, so the plugin's own autocmd still starts
      -- the client with the settings we install here.
      M.apply(vim.api.nvim_get_current_buf())

      vim.api.nvim_create_user_command("SonarQubeConnectedStatus", M.status, {
        desc = "Show SonarQube Connected Mode binding for this repo",
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "sonarqube" then
            M.warn_on_foreign_repo(args.buf)
          end
        end,
      })

      -- Bail before starting the client: a dead JVM just produces a cryptic
      -- "client sonarqube quit with exit code 1" on every buffer open. Still
      -- register :SonarQubeInstallLsp, which only downloads jars and is listed
      -- in `cmd` above, so it must exist once this plugin has loaded.
      if not M.java_ok() then
        require("sonarqube.cmds").setup()
        return
      end

      require("sonarqube").setup({
        rules = { enabled = true },
        javascript = {
          enabled = true, -- covers TypeScript too via the SonarJS analyzer
          clientNodePath = vim.fn.exepath("node"),
        },
        python = { enabled = true },
        html = { enabled = true }, -- Angular templates
      })
    end,
  },
}
