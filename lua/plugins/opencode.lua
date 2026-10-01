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
    opts = {
      -- Keep OpenCode as the single agent interface. Codex authentication and
      -- model selection are managed by the OpenCode CLI/provider configuration.
    },
    init = function()
      -- Required for `opts.auto_reload`
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
