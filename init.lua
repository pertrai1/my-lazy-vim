-- Resolve the `require("async")` module collision between promise-async
-- (nvim-ufo) and async.nvim (refactoring.nvim). Must run before any plugin.
require("config.async-shim")

-- Duplicate-code detection (jscpd) -> quickfix. SonarQube only reports
-- duplication server-side, so this covers it locally.
require("config.jscpd").setup()

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
