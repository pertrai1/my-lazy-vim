return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>h", group = "Harpoon", icon = " " },
        { "<leader>r", group = "Run / REPL", icon = " " },
        { "<leader>R", group = "Refactor", icon = " ", mode = { "n", "x" } },
        { "<leader>t", group = "Terminal", icon = " " },
        { "<leader>y", group = "Yank / Paste", icon = " ", mode = { "n", "x" } },
      },
    },
  },
}
