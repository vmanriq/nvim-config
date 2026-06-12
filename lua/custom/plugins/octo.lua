return {
  'pwntester/octo.nvim',
  cmd = 'Octo',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  keys = {
    -- Listados
    { '<leader>opl', '<cmd>Octo pr list<cr>', desc = '[O]cto [P]R [L]ist (todos)' },
    { '<leader>opR', '<cmd>Octo pr list reviewer=@me state=open<cr>', desc = '[O]cto [P]R [R]eview requested (mías)' },
    { '<leader>opa', '<cmd>Octo pr list assignee=@me state=open<cr>', desc = '[O]cto [P]R [A]ssigned to me' },
    { '<leader>opm', '<cmd>Octo pr list author=@me state=open<cr>', desc = '[O]cto [P]R [M]ine (author=me)' },
    {
      '<leader>opu',
      function()
        vim.ui.input({ prompt = 'GitHub user: ' }, function(user)
          if user and user ~= '' then
            vim.cmd(('Octo pr list author=%s state=open'):format(user))
          end
        end)
      end,
      desc = '[O]cto [P]R by [U]ser (author prompt)',
    },
    -- Ir a un PR específico
    {
      '<leader>opg',
      function()
        vim.ui.input({ prompt = 'PR number or URL: ' }, function(input)
          if not input or input == '' then
            return
          end
          -- Acepta: número (123), URL completa, o "owner/repo#123"
          local n = input:match '#?(%d+)$'
          if n then
            vim.cmd(('Octo pr edit %s'):format(n))
          else
            vim.cmd(('Octo %s'):format(input))
          end
        end)
      end,
      desc = '[O]cto [P]R [G]o to (number or URL)',
    },
    -- Review workflow
    { '<leader>opr', '<cmd>Octo review start<cr>', desc = '[O]cto [P]R [R]eview start' },
    { '<leader>ops', '<cmd>Octo review submit<cr>', desc = '[O]cto [P]R review [S]ubmit' },
    { '<leader>opc', '<cmd>Octo pr checkout<cr>', desc = '[O]cto [P]R [C]heckout' },
    { '<leader>opd', '<cmd>Octo pr diff<cr>', desc = '[O]cto [P]R [D]iff' },
    { '<leader>opb', '<cmd>Octo pr browser<cr>', desc = '[O]cto [P]R open in [B]rowser' },
    { '<leader>ord', '<cmd>Octo review discard<cr>', desc = '[O]cto [R]eview [D]iscard' },
    { '<leader>orr', '<cmd>Octo review resume<cr>', desc = '[O]cto [R]eview [R]esume' },
    -- Ir al PR del blame de la línea actual
    {
      '<leader>ob',
      function()
        local file = vim.api.nvim_buf_get_name(0)
        if file == '' then
          vim.notify('No file in current buffer', vim.log.levels.WARN, { title = 'Octo' })
          return
        end
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local cwd = vim.fn.fnamemodify(file, ':h')

        local blame_cmd = string.format('git -C %s blame -L %d,%d --porcelain -- %s', vim.fn.shellescape(cwd), line, line, vim.fn.shellescape(file))
        local blame_output = vim.fn.system(blame_cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify('git blame failed:\n' .. blame_output, vim.log.levels.ERROR, { title = 'Octo' })
          return
        end

        local sha = blame_output:match '^(%x+)'
        if not sha or sha:match '^0+$' then
          vim.notify('Line not committed yet (or no blame info)', vim.log.levels.WARN, { title = 'Octo' })
          return
        end

        vim.notify(('Looking up PR for %s…'):format(sha:sub(1, 7)), vim.log.levels.INFO, { title = 'Octo' })

        -- Async: gh search PRs containing this commit
        local pr_cmd = { 'gh', 'pr', 'list', '--search', sha, '--state', 'all', '--json', 'number,title,url,state', '--limit', '1' }
        vim.system(pr_cmd, { text = true, cwd = cwd }, function(out)
          vim.schedule(function()
            if out.code ~= 0 then
              vim.notify('gh failed: ' .. (out.stderr or ''), vim.log.levels.ERROR, { title = 'Octo' })
              return
            end
            local ok, prs = pcall(vim.json.decode, out.stdout or '[]')
            if not ok or type(prs) ~= 'table' or #prs == 0 then
              vim.notify(('No PR found for %s'):format(sha:sub(1, 7)), vim.log.levels.WARN, { title = 'Octo' })
              return
            end
            local pr = prs[1]
            vim.notify(('Opening PR #%d (%s): %s'):format(pr.number, pr.state, pr.title), vim.log.levels.INFO, { title = 'Octo' })
            vim.cmd(('Octo pr edit %d'):format(pr.number))
          end)
        end)
      end,
      desc = '[O]cto: open PR from current line [B]lame',
    },
    -- Comentarios / issues
    { '<leader>oc', '<cmd>Octo comment add<cr>', desc = '[O]cto [C]omment add' },
    { '<leader>oi', '<cmd>Octo issue list<cr>', desc = '[O]cto [I]ssue list' },
    { '<leader>oS', '<cmd>Octo search<cr>', desc = '[O]cto [S]earch (GitHub query)' },
  },
  opts = {
    enable_builtin = true,
    picker = 'telescope',
    default_to_projects_v2 = false,
    default_merge_method = 'squash',
    suppress_missing_scope = {
      projects_v2 = true,
    },
    pull_requests = {
      order_by = { field = 'CREATED_AT', direction = 'DESC' },
    },
  },
}
