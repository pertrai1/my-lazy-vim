return {
  "MagicDuck/grug-far.nvim",
  keys = {
    {
      "<leader>sF",
      function()
        require("grug-far").open({ transient = true, prefills = { filesFilter = "" } })
      end,
      mode = { "n", "x" },
      desc = "Search and replace (all files)",
    },
  },
}
