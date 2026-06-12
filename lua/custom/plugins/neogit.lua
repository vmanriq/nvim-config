return {
  'NeogitOrg/neogit',
  cmd = 'Neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    'nvim-telescope/telescope.nvim',
  },
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = '[G]it status (neo[G]it)' },
    { '<leader>gc', '<cmd>Neogit commit<cr>', desc = '[G]it [C]ommit' },
    { '<leader>gp', '<cmd>Neogit pull<cr>', desc = '[G]it [P]ull' },
    { '<leader>gP', '<cmd>Neogit push<cr>', desc = '[G]it [P]ush' },
    { '<leader>gl', '<cmd>Neogit log<cr>', desc = '[G]it [L]og' },
  },
  opts = {
    integrations = {
      diffview = true,
      telescope = true,
    },
    graph_style = 'unicode',
    commit_editor = {
      kind = 'tab',
      show_staged_diff = true,
    },
    signs = {
      hunk = { '', '' },
      item = { '', '' },
      section = { '', '' },
    },
  },
}
