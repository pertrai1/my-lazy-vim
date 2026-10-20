return {
  -- Add which-key group definition for OpenCode
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "OpenCode", icon = " " },
      },
    },
  },

  {
    "NickvanDyke/opencode.nvim",
    -- The main branch targets OpenCode v2; stable releases currently target v1.
    branch = "main",
    dependencies = {
      -- Enhances Ask input and provides the terminal for OpenCode's V2 TUI.
      { "folke/snacks.nvim", opts = { input = { enabled = true } } },
    },
    init = function()
      -- This plugin uses vim.g.opencode_opts, not setup(). Leave opts unset so
      -- lazy.nvim does not try to call a nonexistent setup function.
      -- Provider authentication and model selection stay in the OpenCode CLI.
      -- Allow OpenCode file-edit events to reload buffers.
      vim.opt.autoread = true
    end,
    keys = {
      {
        "<leader>ot",
        function()
          require("snacks.terminal").toggle("opencode", {
            win = { position = "right", width = 80 },
          })
        end,
        desc = "Toggle OpenCode TUI",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@this: ")
        end,
        mode = { "n", "v" },
        desc = "Ask about this",
      },
      {
        "<leader>o+",
        function()
          require("opencode").ask("@buffer: ")
        end,
        desc = "Ask with buffer",
      },
      {
        "<leader>o+",
        function()
          require("opencode").ask("@this: ")
        end,
        mode = "v",
        desc = "Ask with selection",
      },
      {
        "<leader>oe",
        function()
          require("opencode").prompt("Explain @this and its context")
        end,
        mode = { "n", "v" },
        desc = "Explain this code",
      },
      {
        "<leader>os",
        function()
          require("opencode").select()
        end,
        mode = { "n", "v" },
        desc = "Select prompt or command",
      },
    },
  },
}
