-- LSP configuration enhancements
return {
  {
    "neovim/nvim-lspconfig",
    -- Make hover / signature-help floats taller and wider so long TS docs
    -- aren't cut off (they wrap less at width 100 and fit within height 30).
    init = function()
      local orig = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.max_width = opts.max_width or 100
        opts.max_height = opts.max_height or 30
        opts.border = opts.border or "rounded"
        opts.wrap = opts.wrap ~= false
        return orig(contents, syntax, opts, ...)
      end
    end,
    opts = {
      -- Enable inlay hints by default
      inlay_hints = {
        enabled = true,
      },
      -- Server-specific settings
      servers = {
        -- TypeScript
        ts_ls = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
        },
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              hint = {
                enable = true,
                arrayIndex = "Disable",
                setType = true,
              },
              workspace = {
                checkThirdParty = false,
              },
            },
          },
        },
      },
    },
  },
}
