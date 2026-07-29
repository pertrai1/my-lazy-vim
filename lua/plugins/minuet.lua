-- Local inline AI completion through a Qwen FIM model served by llama.cpp.
-- Start llama-server on port 8012 before requesting a completion.
return {
  {
    "milanglacier/minuet-ai.nvim",
    main = "minuet",
    event = "InsertEnter",
    opts = {
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 512,
      request_timeout = 3,
      provider_options = {
        openai_fim_compatible = {
          -- Minuet expects an environment-variable name here. TERM is only a
          -- non-secret placeholder because a local llama.cpp server needs no key.
          api_key = "TERM",
          name = "Llama.cpp",
          end_point = "http://localhost:8012/v1/completions",
          -- llama.cpp selects the model when the server starts.
          model = "PLACEHOLDER",
          optional = {
            max_tokens = 56,
            top_p = 0.9,
          },
          -- Qwen Coder fill-in-the-middle tokens.
          template = {
            prompt = function(context_before_cursor, context_after_cursor)
              return "<|fim_prefix|>"
                .. context_before_cursor
                .. "<|fim_suffix|>"
                .. context_after_cursor
                .. "<|fim_middle|>"
            end,
            suffix = false,
          },
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      keymap = {
        -- Manual-first: request local AI completion only when asked.
        ["<A-y>"] = {
          function(cmp)
            cmp.show({ providers = { "minuet" } })
          end,
        },
      },
      sources = {
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000,
            score_offset = 100,
          },
        },
      },
      completion = {
        trigger = {
          prefetch_on_insert = false,
        },
      },
    },
  },
}
