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
      -- Your configuration, if any — see `lua/opencode/config.lua`
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
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask about this",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@selection: ")
        end,
        mode = "v",
        desc = "Ask about selection",
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
          require("opencode").prompt("@selection", { append = true })
        end,
        mode = "v",
        desc = "Add selection to prompt",
      },
      {
        "<leader>oe",
        function()
          require("opencode").prompt("Explain @cursor and its context")
        end,
        desc = "Explain this code",
      },
      {
        "<leader>on",
        function()
          require("opencode").command("session_new")
        end,
        desc = "New session",
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("messages_half_page_up")
        end,
        desc = "Messages half page up",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("messages_half_page_down")
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
