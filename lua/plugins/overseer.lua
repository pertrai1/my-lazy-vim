local function overseer()
  return require("overseer")
end

local function rerun_last_task()
  local tasks = overseer().list_tasks()
  if vim.tbl_isempty(tasks) then
    vim.notify("No tasks found", vim.log.levels.WARN, { title = "Overseer" })
    return
  end

  overseer().run_action(tasks[1], "restart")
end

return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    dependencies = {
      "stevearc/overseer.nvim",
    },
    opts = function(_, opts)
      local ok, overseer_mod = pcall(require, "overseer")
      if not ok then
        return
      end

      local symbols = {
        [overseer_mod.STATUS.CANCELED] = " ",
        [overseer_mod.STATUS.FAILURE] = " ",
        [overseer_mod.STATUS.SUCCESS] = " ",
        [overseer_mod.STATUS.RUNNING] = " ",
      }

      table.insert(opts.sections.lualine_x, {
        "overseer",
        label = "",
        colored = true,
        symbols = symbols,
        unique = false,
      })
    end,
  },
  {
    "stevearc/overseer.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "OverseerRun", "OverseerTaskAction", "OverseerToggle" },
    keys = {
      { "<leader>rt", "<cmd>OverseerRun<cr>", desc = "Run task" },
      { "<leader>rj", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
      { "<leader>rR", rerun_last_task, desc = "Rerun last task" },
      { "<leader>rv", "<cmd>OverseerToggle bottom<cr>", desc = "View task list" },
    },
    opts = {
      dap = false,
      task_win = {
        padding = 2,
        border = "single",
        win_opts = {
          winblend = 2,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
    },
  },
}
