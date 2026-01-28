-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable system clipboard integration
-- On macOS, use both unnamed and unnamedplus to ensure compatibility
vim.opt.clipboard = "unnamed,unnamedplus"

-- Line numbers
vim.opt.relativenumber = true -- Relative line numbers for faster jumping

-- Scrolling behavior
vim.opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns visible left/right of cursor

-- Undo persistence
vim.opt.undofile = true -- Save undo history to file

-- Performance
vim.opt.updatetime = 250 -- Faster CursorHold events (default 4000ms)

-- Search and substitution
vim.opt.inccommand = "split" -- Live preview of substitutions in split

-- Splits
vim.opt.splitkeep = "screen" -- Keep text on screen when splitting
