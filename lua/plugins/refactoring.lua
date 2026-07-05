return {
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      { "<leader>r", false, mode = { "n", "x" } },
      { "<leader>rs", false, mode = { "n", "x" } },
      { "<leader>ri", false, mode = { "n", "x" } },
      { "<leader>rP", false },
      { "<leader>rp", false, mode = { "n", "x" } },
      { "<leader>rc", false },
      { "<leader>rf", false, mode = { "n", "x" } },
      { "<leader>rF", false, mode = { "n", "x" } },
      { "<leader>rx", false, mode = { "n", "x" } },
      {
        "<leader>Rs",
        function()
          return require("refactoring").select_refactor()
        end,
        mode = { "n", "x" },
        desc = "Select Refactor",
      },
      {
        "<leader>Ri",
        function()
          return require("refactoring").inline_var()
        end,
        mode = { "n", "x" },
        desc = "Inline Variable",
        expr = true,
      },
      {
        "<leader>RP",
        function()
          return require("refactoring.debug").print_loc({ output_location = "below" })
        end,
        desc = "Debug Print Location",
        expr = true,
      },
      {
        "<leader>Rp",
        function()
          return require("refactoring.debug").print_var({ output_location = "below" }) .. "iw"
        end,
        mode = { "n", "x" },
        desc = "Debug Print Variable",
        expr = true,
      },
      {
        "<leader>Rc",
        function()
          return require("refactoring.debug").cleanup({ restore_view = true }) .. "ag"
        end,
        desc = "Debug Cleanup",
        expr = true,
      },
      {
        "<leader>Rf",
        function()
          return require("refactoring").extract_func()
        end,
        mode = { "n", "x" },
        desc = "Extract Function",
        expr = true,
      },
      {
        "<leader>RF",
        function()
          return require("refactoring").extract_func_to_file()
        end,
        mode = { "n", "x" },
        desc = "Extract Function To File",
        expr = true,
      },
      {
        "<leader>Rx",
        function()
          return require("refactoring").extract_var()
        end,
        mode = { "n", "x" },
        desc = "Extract Variable",
        expr = true,
      },
    },
  },
}
