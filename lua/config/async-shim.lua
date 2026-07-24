-- Resolve a module-name collision on `require("async")`.
--
-- Two installed plugins both ship a top-level `lua/async.lua` and hard-require
-- it as `require("async")`, but expect different implementations:
--   * nvim-ufo (via promise-async) expects a *callable* table: `async(fn)` plus
--     an injected `await`, using promise-async's coroutine machinery.
--   * refactoring.nvim (via lewis6991/async.nvim) expects `async.run`,
--     `async.wrap`, `async.await`, etc.
-- Lua's `package.loaded["async"]` can only hold one, so whichever loads first
-- breaks the other (ufo crashes with "attempt to call a table value").
--
-- Their public APIs are disjoint (promise-async: __call/sync/wait;
-- async.nvim: run/wrap/await/iter/...), so we hand back a single merged module
-- that satisfies both. Registered as a preload so it runs on the first
-- `require("async")`, regardless of plugin load order.
package.preload["async"] = function()
  local lazy = vim.fn.stdpath("data") .. "/lazy/"
  local promise_async_dir = lazy .. "promise-async"
  local async_nvim_dir = lazy .. "async.nvim"

  -- Make both plugins' Lua trees resolvable for the file loads below, in case
  -- neither plugin has been added to the runtimepath by lazy.nvim yet.
  vim.opt.runtimepath:append(promise_async_dir)
  vim.opt.runtimepath:append(async_nvim_dir)

  -- Load each real implementation directly by file so neither claims the
  -- shared `async` cache key (loadfile does not populate package.loaded).
  local promise_async = loadfile(promise_async_dir .. "/lua/async.lua")()
  local async_nvim = loadfile(async_nvim_dir .. "/lua/async.lua")()

  local merged = {}
  for k, v in pairs(async_nvim) do -- wrap/iter/sleep/... for refactoring.nvim
    merged[k] = v
  end
  for k, v in pairs(promise_async) do -- sync/wait for nvim-ufo
    merged[k] = v
  end

  -- async.nvim exposes run/await/etc. through its metatable's __index (its
  -- `_core` module), so plain pairs() above misses them. Keep that __index as
  -- a fallback and add promise-async's __call so `async(fn)` still works.
  local async_nvim_index = (getmetatable(async_nvim) or {}).__index
  local promise_call = (getmetatable(promise_async) or {}).__call
  return setmetatable(merged, {
    __index = async_nvim_index, -- run/await/... for refactoring.nvim
    __call = promise_call, -- callable form for nvim-ufo
  })
end
