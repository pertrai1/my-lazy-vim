-- Run from the repository root: nvim --headless -u NONE -l tests/inlay_hints.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local spec = dofile("lua/plugins/lsp.lua")[1]
local excluded = {}
for _, filetype in ipairs(spec.opts.inlay_hints.exclude) do
  excluded[filetype] = true
end

for _, filetype in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
  assert(excluded[filetype], filetype .. " inlay hints should be excluded")
end
assert(spec.opts.inlay_hints.enabled, "inlay hints should remain enabled for other filetypes")

print("ok - TypeScript/JavaScript inlay hints are excluded without disabling other hints")
