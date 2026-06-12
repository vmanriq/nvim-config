return {
  'axelvc/template-string.nvim',
  config = function()
    require('template-string').setup {
      filetypes = {
        'typescript',
        'javascript',
        'typescriptreact',
        'javascriptreact',
        'vue',
        'svelte',
        'html',
        'python',
        'cs',
      }, -- Enable in these filetypes
      jsx_brackets = true, -- Add {} in JSX attributes
      remove_template_string = false, -- Don't auto-revert backticks if no interpolation left
      restore_quotes = {
        normal = [["]], -- Quote type when reverting (not used if remove_template_string = false)
        jsx = [["]],
      },
    }
  end,
}
