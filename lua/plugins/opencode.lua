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
    dependencies = {
      -- Recommended for `ask()`, and required for `toggle()` — otherwise optional
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
          require("opencode").toggle()
        end,
        desc = "Toggle embedded",
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
          require("opencode").prompt("@buffer", { append = true })
        end,
        desc = "Add buffer to prompt",
      },
      {
        "<leader>o+",
        function()
          require("opencode").prompt("@this", { append = true })
        end,
        mode = "v",
        desc = "Add selection to prompt",
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
        "<leader>on",
        function()
          require("opencode").command("session.new")
        end,
        desc = "New session",
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("session.half.page.up")
        end,
        desc = "Messages half page up",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("session.half.page.down")
        end,
        desc = "Messages half page down",
      },
      {
        "<leader>os",
        function()
          require("opencode").select()
        end,
        mode = { "n", "v" },
        desc = "Select prompt",
      },
    },
  },
}
