return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>sg",
      function()
        Snacks.picker.git_files()
      end,
      desc = "Find git files",
    },
    {
      "<leader>sG",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git status",
    },
    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>sD",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer diagnostics",
    },
    {
      "<leader>sc",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Neovim Config" })
      end,
      desc = "Find config files",
    },
    {
      "<leader>s:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command history",
    },
    {
      "<leader>s/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search history",
    },
  },
}
