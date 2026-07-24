-- Pretty inline diagnostics rendered at the cursor
return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000, -- load early so it can take over diagnostic rendering
    opts = {
      preset = "modern",
      options = {
        show_source = true,
        multilines = {
          enabled = true,
          always_show = false,
        },
      },
    },
    init = function()
      -- Avoid rendering the diagnostic twice (default virtual_text + this)
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
