-- Inline reference / definition / implementation counts (VSCode-style codelens)
return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      vt_position = "end_of_line",
    },
  },
}
