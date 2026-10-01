-- Resolve the `require("async")` module collision between promise-async
-- (nvim-ufo) and async.nvim (refactoring.nvim). Must run before any plugin.
require("config.async-shim")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
