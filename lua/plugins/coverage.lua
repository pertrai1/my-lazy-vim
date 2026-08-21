-- Line coverage in the sign column, read from whatever report the project's
-- test tooling already writes. Language-agnostic: works in any repo
-- nvim-coverage supports, not just Node projects.
--
-- Deliberately NOT sourced from SonarQube. SonarQube for IDE never reports
-- coverage -- its analyzer ships `NoOpNewCoverage` -- so coverage is computed
-- server-side from the report CI uploads. Locally it has to be read from that
-- same report.
--
--   <leader>Tc   load the report and show the gutter
--   <leader>Tu   toggle the gutter
--   <leader>TC   per-file summary
--
-- Generate the report with whatever the project uses, e.g.
--   npm run test:coverage        -> coverage/lcov.info
--   go test -coverprofile=coverage.out
--   pytest --cov                 -> .coverage
--   cargo llvm-cov               (rust uses a command, not a file)

-- Each language's report path, as nvim-coverage defines it. Upstream resolves
-- these against the CWD, so opening nvim from a subdirectory silently finds
-- nothing. Re-anchored to the repo root below.
--
-- Several candidates per language where conventions genuinely differ; the
-- first that exists wins. Languages driven by a command rather than a file
-- (rust, swift) are left alone.
local REPORTS = {
  javascript = { "coverage/lcov.info" },
  python = { ".coverage", "coverage.xml" },
  go = { "coverage.out", "cover.out" },
  lua = { "luacov.report.out" },
  ruby = { "coverage/coverage.json" },
  php = { "coverage/cobertura.xml" },
  java = { "build/reports/jacoco/test/jacocoTestReport.xml", "target/site/jacoco/jacoco.xml" },
  cs = { "TestResults/lcov.info" },
  cpp = { "report.info", "coverage.info" },
  dart = { "coverage/lcov.info" },
  elixir = { "cover/lcov.info" },
  julia = { "lcov.info" },
}

-- Filetypes nvim-coverage can load, mapped to the config key they read.
-- Mirrors each language module's `config_alias`.
local FILETYPES = {
  c = "cpp",
  cpp = "cpp",
  cs = "cs",
  dart = "dart",
  elixir = "elixir",
  go = "go",
  java = "java",
  javascript = "javascript",
  javascriptreact = "javascript",
  julia = "julia",
  lua = "lua",
  php = "php",
  python = "python",
  ruby = "ruby",
  rust = "rust",
  swift = "swift",
  typescript = "javascript",
  typescriptreact = "javascript",
  vue = "javascript",
}

local function repo_root(bufnr)
  local name = bufnr and vim.api.nvim_buf_get_name(bufnr) or vim.api.nvim_buf_get_name(0)
  return vim.fs.root(name ~= "" and name or vim.fn.getcwd(), { ".git" })
end

-- First existing candidate for `lang`, anchored at the repo root.
local function report_path(lang, bufnr)
  local root = repo_root(bufnr)
  if not root then
    return nil
  end
  for _, rel in ipairs(REPORTS[lang] or {}) do
    local path = vim.fs.joinpath(root, rel)
    if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return nil
end

-- Build the `lang` table nvim-coverage expects: a function per language, so
-- the root is resolved at load time rather than baked in at startup.
local function lang_opts()
  local opts = {}
  for lang in pairs(REPORTS) do
    opts[lang] = {
      coverage_file = function()
        -- Fall back to the first candidate so upstream reports a missing file
        -- rather than erroring on a nil path.
        return report_path(lang) or vim.fs.joinpath(repo_root() or vim.fn.getcwd(), REPORTS[lang][1])
      end,
    }
  end
  return opts
end

return {
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Commands are created inside setup(), so they need load triggers.
    cmd = {
      "Coverage",
      "CoverageLoad",
      "CoverageLoadLcov",
      "CoverageShow",
      "CoverageHide",
      "CoverageToggle",
      "CoverageClear",
      "CoverageSummary",
    },
    -- Signs are session state, not a property of the file: nothing appears
    -- until the report is loaded, so opening a file shows an empty gutter even
    -- at 100% coverage. Load it automatically when a supported buffer opens in
    -- a repo that actually has a report.
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("coverage_autoload", { clear = true }),
        -- FileType rather than BufReadPost: upstream dispatches on
        -- vim.bo.filetype, which is not set yet at BufReadPost.
        pattern = vim.tbl_keys(FILETYPES),
        callback = function(args)
          local lang = FILETYPES[vim.bo[args.buf].filetype]
          -- Command-driven languages have no report to probe for; leave those
          -- to an explicit <leader>Tc.
          if not lang or not REPORTS[lang] then
            return
          end

          -- Guard on the report existing, otherwise every buffer open in a
          -- repo without coverage notifies "No coverage file exists."
          if not report_path(lang, args.buf) then
            return
          end

          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              pcall(vim.cmd, "Coverage")
            end
          end)
        end,
      })
    end,
    keys = {
      { "<leader>Tc", "<cmd>Coverage<cr>", desc = "Coverage (load & show)" },
      { "<leader>TC", "<cmd>CoverageSummary<cr>", desc = "Coverage summary" },
      { "<leader>Tu", "<cmd>CoverageToggle<cr>", desc = "Coverage toggle gutter" },
    },
    opts = function()
      return {
        commands = true,
        -- Re-read the report when it changes on disk, so a test run refreshes
        -- the gutter without reloading by hand.
        auto_reload = true,
        lang = lang_opts(),
      }
    end,
  },
}
