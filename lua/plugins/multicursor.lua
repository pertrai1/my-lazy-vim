return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      mc.addKeymapLayer(function(set)
        set("n", "<Esc>", function()
          if mc.cursorsEnabled() then
            mc.clearCursors()
          else
            mc.enableCursors()
          end
        end)
      end)
    end,
    keys = {
      {
        "<C-n>",
        function()
          require("multicursor-nvim").matchAddCursor(1)
        end,
        mode = { "n", "x" },
        desc = "Add cursor to next match",
      },
      {
        "<leader>Ms",
        function()
          require("multicursor-nvim").matchSkipCursor(1)
        end,
        mode = { "n", "x" },
        desc = "Skip next match",
      },
      {
        "<leader>Ma",
        function()
          require("multicursor-nvim").matchAllAddCursors()
        end,
        mode = { "n", "x" },
        desc = "Add cursors to all matches",
      },
      {
        "<leader>Mj",
        function()
          require("multicursor-nvim").lineAddCursor(1)
        end,
        mode = { "n", "x" },
        desc = "Add cursor below",
      },
      {
        "<leader>Mk",
        function()
          require("multicursor-nvim").lineAddCursor(-1)
        end,
        mode = { "n", "x" },
        desc = "Add cursor above",
      },
      {
        "<leader>Mc",
        function()
          require("multicursor-nvim").clearCursors()
        end,
        mode = { "n", "x" },
        desc = "Clear cursors",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>M", group = "Multi-cursor", mode = { "n", "x" } },
      },
    },
  },
}
