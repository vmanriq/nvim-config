return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        typescript = { 'eslint_d' },
        javascript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        markdown = { 'markdownlint' },
      }

      -- ESLint auto-fix current file
      vim.keymap.set('n', '<leader>lf', function()
        local file = vim.fn.expand '%:p'
        if file == '' then
          return
        end
        vim.cmd('silent !eslint_d --fix ' .. vim.fn.shellescape(file))
        vim.cmd 'edit'
      end, { desc = 'ESLint auto-[F]ix current file' })

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if not vim.bo.modifiable then
            return
          end

          local linters = lint.linters_by_ft[vim.bo.filetype] or {}
          for _, name in ipairs(linters) do
            local linter = lint.linters[name]
            if linter then
              local cmd = type(linter.cmd) == 'function' and linter.cmd() or linter.cmd
              if type(cmd) == 'string' and vim.fn.executable(cmd) == 0 then
                return
              end
            end
          end

          local clients = vim.lsp.get_clients { bufnr = 0 }
          local cwd = (clients[1] or {}).root_dir
          lint.try_lint(nil, cwd and { cwd = cwd } or {})
        end,
      })
    end,
  },
}
