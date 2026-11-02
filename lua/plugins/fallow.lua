return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        fallow = {
          mason = false, -- Installed separately with npm install -g fallow.
          cmd = { "fallow-lsp" },
          filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
          root_markers = { ".fallowrc.json", "package.json", ".git" },
        },
      },
    },
  },
}
