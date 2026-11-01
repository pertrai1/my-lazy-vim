-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- Register jscpd shortcuts after LazyVim sets the leader key.
require("config.jscpd").setup()

-- Hide relative line numbers while inserting
-- Only toggle in normal file buffers; terminals, pickers and prompts manage
-- their own line numbers.
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" then
      vim.opt_local.relativenumber = false
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" then
      vim.opt_local.relativenumber = true
    end
  end,
})

-- auto-save before herdr pane or terminal launch
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.cmd("silent! wall")
  end,
})
