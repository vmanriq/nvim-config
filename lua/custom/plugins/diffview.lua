return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    vim.keymap.set('n', '<leader>go', '<cmd>DiffviewOpen<CR>', { desc = '[G]it [O]pen diff view' })
    vim.keymap.set('n', '<leader>gx', '<cmd>DiffviewClose<CR>', { desc = '[G]it close diff view' })
  end,
}
