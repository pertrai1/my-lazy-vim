-- Quickly insert a print/log statement for the text under an operator/motion.
-- e.g. <leader>Piw prints the word under the cursor.
return {
  {
    "rareitems/printer.nvim",
    keys = {
      { "<leader>P", desc = "Print variable (operator)", mode = { "n", "x" } },
    },
    opts = {
      keymap = "<leader>P",
    },
  },
}
