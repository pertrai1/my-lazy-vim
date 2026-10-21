-- Reuse the existing task UI; the CodeScene CLI remains entirely optional.
return {
  {
    "stevearc/overseer.nvim",
    cmd = { "CodeScene" },
    opts = function()
      require("config.codescene").setup()
    end,
  },
}
