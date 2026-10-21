-- Run from the repository root: nvim --headless -u NONE -l tests/inlay_hints.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local inlay_hints = require("config.inlay_hints")
local lines = { "const value = 1", "" }

assert(inlay_hints.valid_position({ position = { line = 0, character = 5 } }, lines))
assert(inlay_hints.valid_position({ position = { line = 1, character = 0 } }, lines))
assert(not inlay_hints.valid_position({ position = { line = 0, character = 16 } }, lines))
assert(not inlay_hints.valid_position({ position = { line = 0, character = -1 } }, lines))
assert(not inlay_hints.valid_position({ position = { line = 3, character = 0 } }, lines))

local filtered = inlay_hints.filter_invalid_positions({
  { position = { line = 0, character = 5 } },
  { position = { line = 0, character = 99 } },
}, lines)
assert(#filtered == 1 and filtered[1].position.character == 5)

local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
local previous_handler = vim.lsp.handlers["textDocument/inlayHint"]
local received
vim.lsp.handlers["textDocument/inlayHint"] = function(_, result)
  received = result
end
dofile("lua/plugins/lsp.lua")[1].init()
vim.lsp.handlers["textDocument/inlayHint"](nil, {
  { position = { line = 0, character = 5 } },
  { position = { line = 0, character = 99 } },
}, { bufnr = buffer })
assert(#received == 1 and received[1].position.character == 5)
vim.lsp.handlers["textDocument/inlayHint"] = previous_handler
vim.api.nvim_buf_delete(buffer, { force = true })

print("ok - inlay hints with invalid buffer positions are discarded")
