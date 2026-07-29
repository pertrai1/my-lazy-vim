local function neotest()
  return require("neotest")
end

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
        ["neotest-jest"] = {},
      },
      discovery = {
        enabled = true,
        concurrent = 4,
      },
      running = {
        concurrent = true,
      },
      summary = {
        enabled = true,
        follow = true,
      },
      output = {
        open_on_run = "short",
      },
    },
    keys = {
      -- Keep <leader>t available for the existing terminal workflow.
      { "<leader>t", false },
      { "<leader>ta", false },
      { "<leader>tt", false },
      { "<leader>tT", false },
      { "<leader>tr", false },
      { "<leader>tl", false },
      { "<leader>ts", false },
      { "<leader>to", false },
      { "<leader>tO", false },
      { "<leader>tS", false },
      { "<leader>tw", false },

      { "<leader>T", "", desc = "+test" },
      {
        "<leader>Tn",
        function()
          neotest().run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>Tf",
        function()
          neotest().run.run(vim.fn.expand("%"))
        end,
        desc = "Run test file",
      },
      {
        "<leader>Ta",
        function()
          neotest().run.run(vim.uv.cwd())
        end,
        desc = "Run all tests",
      },
      {
        "<leader>Tl",
        function()
          neotest().run.run_last()
        end,
        desc = "Run last test",
      },
      {
        "<leader>Ts",
        function()
          neotest().summary.toggle()
        end,
        desc = "Toggle test summary",
      },
      {
        "<leader>To",
        function()
          neotest().output.open({ enter = true, auto_close = true })
        end,
        desc = "Show test output",
      },
      {
        "<leader>TO",
        function()
          neotest().output_panel.toggle()
        end,
        desc = "Toggle output panel",
      },
      {
        "<leader>Tw",
        function()
          neotest().watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle test watch",
      },
      {
        "<leader>Tx",
        function()
          neotest().run.stop()
        end,
        desc = "Stop test",
      },
      {
        "<leader>Td",
        function()
          neotest().run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest test",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>T", group = "Test", icon = "󰙨 " },
      },
    },
  },
}
