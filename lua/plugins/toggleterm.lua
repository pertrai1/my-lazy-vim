-- Persistent toggleable terminal — for running MCP servers, agent CLIs,
-- and tailing logs alongside code without leaving Neovim.
--
-- Swapped from toggleterm.nvim to snacks.terminal to test it out.
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
      function()
        Snacks.terminal(nil, { win = { position = "bottom", height = 15 } })
      end,
      desc = "Toggle terminal (horizontal)",
      mode = { "n", "t" },
    },
    {
      "<leader>tt",
      function()
        Snacks.terminal(nil, { win = { position = "bottom", height = 15 } })
      end,
      desc = "Toggle terminal (horizontal)",
    },
    {
      "<leader>tv",
      function()
        Snacks.terminal(nil, { win = { position = "right", width = 80 } })
      end,
      desc = "Toggle terminal (vertical)",
    },
    {
      "<leader>tf",
      function()
        Snacks.terminal(nil, { win = { position = "float" } })
      end,
      desc = "Toggle terminal (float)",
    },
  },
}
