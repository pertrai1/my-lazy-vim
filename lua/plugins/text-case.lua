-- Convert between snake_case / camelCase / PascalCase / ... via `ga` motions.
-- (`gA` performs an LSP rename in the chosen case.)
return {
  {
    "johmsalas/text-case.nvim",
    keys = {
      { "ga", desc = "Text case (motion)", mode = { "n", "x" } },
      { "gA", desc = "Text case (LSP rename)", mode = { "n", "x" } },
    },
    config = function()
      require("textcase").setup({})
    end,
  },
}
