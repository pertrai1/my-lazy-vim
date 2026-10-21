-- LSP configuration enhancements
return {
  {
    "neovim/nvim-lspconfig",
    -- Make hover / signature-help floats taller and wider so long TS docs
    -- aren't cut off (they wrap less at width 100 and fit within height 30).
    init = function()
      local inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]
      if inlay_hint_handler then
        vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, ...)
          if not err and result and ctx.bufnr and vim.api.nvim_buf_is_loaded(ctx.bufnr) then
            result = require("config.inlay_hints").filter_invalid_positions(
              result,
              vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
            )
          end
          return inlay_hint_handler(err, result, ctx, ...)
        end
      end

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
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            suggest = {
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
