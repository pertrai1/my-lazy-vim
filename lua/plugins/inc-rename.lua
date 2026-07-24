-- Live-preview LSP rename.
-- LazyVim automatically routes <leader>cr through inc-rename when it is installed.
return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
  },
}
