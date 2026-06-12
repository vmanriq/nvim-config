return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {},
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
    { '<leader>xe', '<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.ERROR<cr>', desc = 'Filter [E]rrors only (Trouble)' },
    { '<leader>xw', '<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.WARN<cr>', desc = 'Filter [W]arnings only (Trouble)' },
    { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = '[Q]uickfix list (Trouble)' },
  },
}
