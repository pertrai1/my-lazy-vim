-- Persistent toggleable terminal — for running MCP servers, agent CLIs,
-- and tailing logs alongside code without leaving Neovim.
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = 15,
    open_mapping = [[<c-\>]],
    direction = "horizontal",
    shade_terminals = true,
    persist_size = true,
  },
  keys = function()
    local keys = {
      {
        "<leader>tt",
        "<cmd>ToggleTerm direction=horizontal<cr>",
        desc = "Toggle terminal (horizontal)",
      },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "Toggle terminal (vertical)" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle terminal (float)" },
    }
    return keys
  end,
}
