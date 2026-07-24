-- Edit and create snippets from inside Neovim.
-- Snippets are written to the dir below as VSCode-style JSON. To have them show
-- up in completion, register this dir with blink.cmp (see note in your summary).
return {
  {
    "chrisgrieser/nvim-scissors",
    keys = {
      {
        "<leader>Se",
        function()
          require("scissors").editSnippet()
        end,
        desc = "Edit snippet",
      },
      {
        "<leader>Sa",
        function()
          require("scissors").addNewSnippet()
        end,
        mode = { "n", "x" },
        desc = "Add new snippet",
      },
    },
    opts = {
      snippetDir = vim.fn.stdpath("config") .. "/snippets",
    },
  },
}
