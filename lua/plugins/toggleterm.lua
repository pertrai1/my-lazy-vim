local function terminal(cmd, opts)
  return function()
    Snacks.terminal(cmd, opts)
  end
end

return {
  "folke/snacks.nvim",
  opts = {
    quickfile = { enabled = true },
    terminal = {
      win = {
        style = "terminal",
      },
    },
  },
  keys = {
    {
      "<leader><space>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Find Files (smart)",
    },
    {
      "<c-\\>",
      terminal(nil, { count = 1, win = { position = "bottom", height = 15 } }),
      desc = "Toggle terminal (horizontal)",
      mode = { "n", "t" },
    },
    {
      "<leader>tt",
      terminal(nil, { count = 1, win = { position = "bottom", height = 15 } }),
      desc = "Toggle shell terminal",
    },
    {
      "<leader>tv",
      terminal(nil, { count = 2, win = { position = "right", width = 80 } }),
      desc = "Toggle terminal (vertical)",
    },
    {
      "<leader>tf",
      terminal(nil, { count = 3, win = { position = "float" } }),
      desc = "Toggle terminal (float)",
    },
    {
      "<leader>tl",
      terminal(nil, { count = 5, win = { position = "bottom", height = 12 } }),
      desc = "Toggle logs terminal",
    },
    {
      "<leader>tr",
      terminal(nil, { count = 6, win = { position = "bottom", height = 18 } }),
      desc = "Toggle REPL terminal",
    },
  },
}
