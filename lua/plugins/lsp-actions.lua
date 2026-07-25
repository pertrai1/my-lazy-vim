local function source_action(kind)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = {
        only = { kind },
        diagnostics = vim.diagnostic.get(0),
      },
    })
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>co",
        source_action("source.organizeImports"),
        desc = "Organize imports",
      },
      {
        "<leader>cE",
        source_action("source.fixAll.eslint"),
        desc = "ESLint fix all",
      },
      {
        "<leader>cF",
        source_action("source.fixAll"),
        desc = "Source fix all",
      },
      {
        "<leader>cq",
        function()
          vim.diagnostic.setqflist({ open = true })
        end,
        desc = "Diagnostics quickfix",
      },
      {
        "<leader>cl",
        function()
          vim.diagnostic.setloclist({ open = true })
        end,
        desc = "Diagnostics loclist",
      },
      {
        "]d",
        function()
          vim.diagnostic.jump({ count = 1, float = true })
        end,
        desc = "Next diagnostic",
      },
      {
        "[d",
        function()
          vim.diagnostic.jump({ count = -1, float = true })
        end,
        desc = "Prev diagnostic",
      },
    },
  },
}
