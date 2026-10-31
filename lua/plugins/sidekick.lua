---@type LazySpec
-- NOTE: Sidekick AI - Copilot NES + AI CLI integration

-- Ask a free-form question about `ctx` ({this}, {file}, ...). Context is
-- rendered before the input opens because that discards the visual selection.
local function ask(ctx, title)
  local cli = require("sidekick.cli")
  local _, text = cli.render({ msg = ctx })
  if not text then
    return
  end
  vim.ui.input({ prompt = title }, function(question)
    if not question or question == "" then
      return
    end
    cli.send({ text = text, focus = true })
    cli.send({ msg = question, submit = true })
  end)
end

local function prompt(name)
  return function()
    require("sidekick.cli").send({ prompt = name, submit = true, focus = true })
  end
end
return {
  "folke/sidekick.nvim",
  event = "VeryLazy",
  opts = {
    nes = {
      enabled = function(buf)
        return vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false
      end,
      debounce = 100,
      diff = {
        inline = "words",
        show = "always",
      },
      signs = true,
    },
    cli = {
      watch = true,
      mux = {
        backend = "tmux",
        -- Disabled: Sidekick kept reattaching to a dead tmux session whose cwd
        -- was gone, so tools failed with "working directory was deleted".
        enabled = false,
        create = "terminal",
      },
      picker = "snacks",
      win = {
        layout = "right",
        split = {
          width = 80,
          height = 20,
        },
        keys = {
          hide_n = { "q", "hide", mode = "n", desc = "hide the terminal window" },
          hide_ctrl_q = { "<c-q>", "hide", mode = "n", desc = "hide the terminal window" },
          hide_ctrl_dot = { "<c-.>", "hide", mode = "nt", desc = "hide the terminal window" },
          hide_ctrl_z = { "<c-z>", "blur", mode = "nt", desc = "go back to the previous window" },
          prompt = { "<c-p>", "prompt", mode = "t", desc = "insert prompt or context" },
          stopinsert = { "<c-q>", "stopinsert", mode = "t", desc = "enter normal mode" },
        },
      },
      -- The CLIs used day to day, each with its own keymap (<leader>ac/ax/ao).
      -- Sidekick merges in its defaults, so the <leader>as picker filters to
      -- installed tools instead.
      tools = {
        claude = {},
        codex = {},
        opencode = {},
      },
      prompts = {
        changes = "Can you review my changes?",
        diagnostics = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
        diagnostics_all = "Can you help me fix these diagnostics?\n{diagnostics_all}",
        document = "Add documentation to {function|line}",
        explain = "Explain {this}",
        fix = "Can you fix {this}?",
        optimize = "How can {this} be optimized?",
        review = "Can you review {file} for any issues or improvements?",
        tests = "Can you write tests for {this}?",
        refactor = "Suggest a refactor of {this} that simplifies it without changing behavior.",
        security = "Review {this} for security issues such as injection, unsafe input handling and secrets.",
        types = "Can you improve the typing of {this}? Remove any/unknown where a precise type is possible.",
        quickfix = "Help me work through this quickfix list:\n{quickfix}",
        commit = "Look at my staged changes and write a conventional commit message.",
        pr = "Look at the changes on this branch versus main and draft a pull request description.",
      },
    },
    copilot = {
      status = {
        enabled = true,
        level = vim.log.levels.WARN,
      },
    },
  },
  keys = {
    {
      "<tab>",
      function()
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>"
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      "<c-.>",
      function()
        require("sidekick.cli").focus()
      end,
      desc = "Sidekick Focus",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Select CLI Tool",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<leader>aq",
      function()
        ask("{this}", "Ask about this: ")
      end,
      mode = { "n", "x" },
      desc = "Ask about selection / cursor",
    },
    {
      "<leader>aQ",
      function()
        ask("{file}", "Ask about this file: ")
      end,
      desc = "Ask about file",
    },
    { "<leader>ae", prompt("explain"), mode = { "n", "x" }, desc = "Explain this" },
    { "<leader>ar", prompt("review"), mode = { "n", "x" }, desc = "Review this" },
    { "<leader>aR", prompt("refactor"), mode = { "n", "x" }, desc = "Suggest refactor" },
    { "<leader>aF", prompt("fix"), mode = { "n", "x" }, desc = "Fix this" },
    { "<leader>aT", prompt("tests"), mode = { "n", "x" }, desc = "Write tests" },
    { "<leader>aD", prompt("diagnostics"), desc = "Fix buffer diagnostics" },
    { "<leader>aE", prompt("diagnostics_all"), desc = "Fix all diagnostics" },
    { "<leader>aS", prompt("security"), mode = { "n", "x" }, desc = "Security review" },
    { "<leader>aC", prompt("changes"), desc = "Review my changes" },
    { "<leader>aG", prompt("commit"), desc = "Write commit message" },
    { "<leader>aP", prompt("pr"), desc = "Draft PR description" },
    { "<leader>aK", prompt("quickfix"), desc = "Work through quickfix list" },
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>ax",
      function()
        require("sidekick.cli").toggle({ name = "codex", focus = true })
      end,
      desc = "Sidekick Toggle Codex",
    },
    {
      "<leader>ao",
      function()
        require("sidekick.cli").toggle({ name = "opencode", focus = true })
      end,
      desc = "Sidekick Toggle OpenCode",
    },
  },
  dependencies = {
    "folke/snacks.nvim",
  },
}
