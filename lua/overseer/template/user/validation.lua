---@type overseer.TemplateFileProvider
return {
  generator = function(opts)
    local templates = require("config.validation_tasks").templates(opts.dir)
    if vim.tbl_isempty(templates) then
      return "No validation tasks detected for this project"
    end
    return templates
  end,
}
