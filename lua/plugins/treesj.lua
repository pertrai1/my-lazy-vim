-- Smart split/join of blocks (args, dicts, arrays, ...)
return {
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "<leader>j",
        function()
          require("treesj").toggle()
        end,
        desc = "Toggle Split/Join",
      },
    },
    opts = {
      use_default_keymaps = false,
    },
  },
}
