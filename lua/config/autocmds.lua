-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- Hide relative line numbers while inserting
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.opt_local.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.opt_local.relativenumber = true
  end,
})

-- auto-save before herdr pane or terminal launch
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.cmd("silent! wall")
  end,
})
