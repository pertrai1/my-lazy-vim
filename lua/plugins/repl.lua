return {
  -- Add which-key group definition for REPL
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>r", group = "REPL", icon = " " },
      },
    },
  },

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
      { "<leader>rr", "<Plug>SnipRun", desc = "Run code" },
      { "<leader>rf", "<Plug>SnipRunOperator", desc = "Run operator" },
      { "<leader>rr", "<Plug>SnipRun", mode = "v", desc = "Run selection" },
    },
  },

  -- Iron.nvim for REPL integration  
  {
    "hkupty/iron.nvim",
    config = function()
      local iron = require("iron.core")
      iron.setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = { "zsh" } },
            python = { command = { "python3" } },
            javascript = { command = { "node" } },
          },
          repl_open_cmd = require("iron.view").bottom(40),
        },
        keymaps = {
          send_motion = "<space>sc",
          visual_send = "<space>sc",
          send_file = "<space>sf",
          send_line = "<space>sl",
          send_paragraph = "<space>sp",
          send_until_cursor = "<space>su",
          send_mark = "<space>sm",
          mark_motion = "<space>mc",
          mark_visual = "<space>mc",
          remove_mark = "<space>md",
          cr = "<space>s<cr>",
          interrupt = "<space>s<space>",
          exit = "<space>sq",
          clear = "<space>cl",
        },
        highlight = { italic = true },
      })
    end,
    keys = {
      { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Start REPL" },
      { "<leader>rq", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
    },
  },
}