-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Quick save without taking over the windows prefix
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("i", "<C-s>", "<Esc><cmd>w<cr>a", { desc = "Save" })
vim.keymap.set("v", "<C-s>", "<Esc><cmd>w<cr>gv", { desc = "Save" })

-- Move lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered during navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search centered" })

-- Keep cursor position when joining lines
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Paste without losing register content
vim.keymap.set("x", "<leader>yp", [["_dP]], { desc = "Paste without yank" })

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>yd", [["_d]], { desc = "Delete without yank" })
