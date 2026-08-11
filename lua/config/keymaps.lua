-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Ctrl+Shift+hjkl: move cursor like arrow keys
map("i", "<C-S-h>", "<Left>", { desc = "Move cursor left" })
map("i", "<C-S-j>", "<Down>", { desc = "Move cursor down" })
map("i", "<C-S-k>", "<Up>", { desc = "Move cursor up" })
map("i", "<C-S-l>", "<Right>", { desc = "Move cursor right" })

-- Better word deletion in insert mode
map("i", "<M-BS>", "<C-w>", { desc = "Delete word backward" })
map("i", "<C-BS>", "<C-w>", { desc = "Delete word backward" })
map("i", "<C-H>", "<C-w>", { desc = "Delete word backward (fallback)" })

-- Quick save without taking over the windows prefix
map("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save" })
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map("i", "<C-s>", "<Esc><cmd>w<cr>a", { desc = "Save" })
map("v", "<C-s>", "<Esc><cmd>w<cr>gv", { desc = "Save" })

-- Reload config
map("n", "<leader>rc", "<cmd>source $MYVIMRC<cr>", { desc = "Reload config" })

-- Select all with Ctrl+a
map("n", "<C-a>", "ggVG", { desc = "Select all" })
map("i", "<C-a>", "<Esc>ggVG", { desc = "Select all" })
map("v", "<C-a>", "<Esc>ggVG", { desc = "Select all" })

-- Shift+Alt+arrows: duplicate line or selection
map("n", "<S-M-Down>", ":t.<CR>", { desc = "Duplicate line down" })
map("n", "<S-M-Up>", ":t.-1<CR>", { desc = "Duplicate line up" })
map("v", "<S-M-Down>", ":t'><CR>gv", { desc = "Duplicate selection down" })
map("v", "<S-M-Up>", ":t'<-1<CR>gv", { desc = "Duplicate selection up" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered during navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })
map("n", "n", "nzzzv", { desc = "Next search centered" })
map("n", "N", "Nzzzv", { desc = "Prev search centered" })

-- Keep cursor position when joining lines
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Paste without losing register content
map("x", "<leader>yp", [["_dP]], { desc = "Paste without yank" })

-- Delete without yanking
map({ "n", "v" }, "<leader>yd", [["_d]], { desc = "Delete without yank" })
