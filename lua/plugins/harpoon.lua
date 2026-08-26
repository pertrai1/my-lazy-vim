local function harpoon()
  return require("harpoon")
end

return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      settings = {
        save_on_toggle = false,
        sync_on_ui_close = false,
        key = function()
          return require("lazyvim.util").root.cwd()
        end,
      },
    },
    config = function(_, opts)
      harpoon().setup(opts)
    end,
    keys = {
      {
        "<leader>ma",
        function()
          harpoon():list():add()
        end,
        desc = "Mark file",
      },
      {
        "<leader>mm",
        function()
          harpoon().ui:toggle_quick_menu(harpoon():list())
        end,
        desc = "Marked files menu",
      },
      {
        "<leader>mj",
        function()
          harpoon():list():next()
        end,
        desc = "Next marked file",
      },
      {
        "<leader>mk",
        function()
          harpoon():list():prev()
        end,
        desc = "Previous marked file",
      },
      {
        "<leader>m1",
        function()
          harpoon():list():select(1)
        end,
        desc = "Go to marked file 1",
      },
      {
        "<leader>m2",
        function()
          harpoon():list():select(2)
        end,
        desc = "Go to marked file 2",
      },
      {
        "<leader>m3",
        function()
          harpoon():list():select(3)
        end,
        desc = "Go to marked file 3",
      },
      {
        "<leader>m4",
        function()
          harpoon():list():select(4)
        end,
        desc = "Go to marked file 4",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>m", group = "Marks / Harpoon", icon = "󱡅 " })
    end,
  },
}
