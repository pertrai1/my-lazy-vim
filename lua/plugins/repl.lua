return {
  -- Sniprun for instant code execution
  {
    "michaelb/sniprun",
    branch = "master",
    build = "sh install.sh",
    config = function()
      require("sniprun").setup({
        selected_interpreters = { "JS_TS_deno", "Python3_fifo" },
        repl_enable = { "JS_TS_deno", "Python3_fifo" },
        display = {
          "Classic", -- Display results in command line
          "VirtualTextOk", -- Display results as virtual text
        },
      })
    end,
    keys = {
      { "<leader>rr", "<Plug>SnipRun", desc = "Run Code" },
      { "<leader>rm", "<Plug>SnipRunOperator", desc = "Run Motion" },
      { "<leader>rr", "<Plug>SnipRun", mode = "v", desc = "Run Selection" },
    },
  },

  -- Iron.nvim for REPL integration
  {
    "hkupty/iron.nvim",
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = { "zsh" } },
            python = { command = { "python3" } },
            javascript = { command = { "node" } },
          },
          repl_open_cmd = require("iron.view").bottom(40),
        },
        highlight = { italic = true },
      })
    end,
    keys = {
      { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Open REPL" },
      { "<leader>rS", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
      { "<leader>ro", "<cmd>IronFocus<cr>", desc = "Focus REPL" },
      {
        "<leader>rc",
        function()
          require("iron.core").run_motion("send_motion")
        end,
        desc = "Send Motion",
      },
      {
        "<leader>rc",
        function()
          require("iron.core").visual_send()
        end,
        mode = "v",
        desc = "Send Selection",
      },
      {
        "<leader>rf",
        function()
          require("iron.core").send_file()
        end,
        desc = "Send File",
      },
      {
        "<leader>rl",
        function()
          require("iron.core").send_line()
        end,
        desc = "Send Line",
      },
      {
        "<leader>rp",
        function()
          require("iron.core").send_paragraph()
        end,
        desc = "Send Paragraph",
      },
      {
        "<leader>ru",
        function()
          require("iron.core").send_until_cursor()
        end,
        desc = "Send Until Cursor",
      },
      {
        "<leader>ri",
        function()
          require("iron.core").send(nil, string.char(03))
        end,
        desc = "Interrupt REPL",
      },
      {
        "<leader>rq",
        function()
          require("iron.core").close_repl()
        end,
        desc = "Quit REPL",
      },
      {
        "<leader>rx",
        function()
          require("iron.core").send(nil, string.char(12))
        end,
        desc = "Clear REPL",
      },
    },
  },
}