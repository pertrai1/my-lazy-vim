return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      -- Show help/keys footer inside the popup so mappings are easy to discover
      show_help = true,
      show_keys = true,
      spec = {
        -- Discovery helpers (press <leader>h to browse all shortcuts)
        { "<leader>h", group = "Help / Keymaps", icon = "󰋖 " },

        -- Existing groups
        { "<leader>r", group = "Run / REPL", icon = " " },
        { "<leader>R", group = "Refactor", icon = " ", mode = { "n", "x" } },
        { "<leader>t", group = "Terminal", icon = " " },
        { "<leader>y", group = "Yank / Paste", icon = " ", mode = { "n", "x" } },

        -- New plugin groups
        { "<leader>gd", group = "Diffview", icon = " " },
        { "<leader>S", group = "Snippets", icon = " " },

        -- New single-key actions (labelled so they show up nicely)
        { "<leader>j", desc = "Toggle Split/Join", icon = " " },
        { "<leader>P", desc = "Print variable", icon = " ", mode = { "n", "x" } },
      },
    },
    keys = {
      {
        "<leader>hk",
        function()
          require("which-key").show({ global = true })
        end,
        desc = "All keymaps (which-key)",
      },
      {
        "<leader>hb",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer keymaps (which-key)",
      },
      {
        "<leader>hK",
        "<cmd>WhichKey<cr>",
        desc = "Browse all which-key mappings",
      },
    },
  },
}
