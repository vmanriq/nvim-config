return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      require('toggleterm').setup {
        -- Keybinding to toggle terminal
        open_mapping = [[<c-\>]],
        shade_terminals = true, -- Darkens terminal background a bit
        shading_factor = 2, -- How much to darken (1-3)
        start_in_insert = true, -- Automatically enter insert mode
        insert_mappings = true, -- Allow <c-\> in insert mode too
        persist_size = true, -- Keep same size between sessions
        direction = 'horizontal', -- You can also use "float" or "tab"
        close_on_exit = true, -- Close terminal buffer when process exits
        shell = vim.o.shell, -- Use your default shell

        -- Float window options
        float_opts = {
          border = 'curved',
          width = math.floor(vim.o.columns * 0.8),
          height = math.floor(vim.o.lines * 0.8),
          winblend = 3, -- Transparency
        },
      }

      -- OPTIONAL: Keymaps for quickly switching direction
      vim.keymap.set('n', '<leader>th', '<cmd>ToggleTerm direction=horizontal<cr>', { desc = 'Horizontal terminal' })
      vim.keymap.set('n', '<leader>tv', '<cmd>ToggleTerm direction=vertical<cr>', { desc = 'Vertical terminal' })
      vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', { desc = 'Floating terminal' })
    end,
  },
}
