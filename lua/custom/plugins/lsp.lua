return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    { 'antosha417/nvim-lsp-file-operations', config = true },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require 'lspconfig'
    local util = require 'lspconfig.util'

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require 'cmp_nvim_lsp'

    local keymap = vim.keymap -- for conciseness

    local opts = { noremap = true, silent = true }
    local on_attach = function(client, bufnr)
      opts.buffer = bufnr

      local is_list = vim.islist or vim.tbl_islist
      local notify = function(message, level)
        vim.notify(message, level or vim.log.levels.INFO, { title = 'LSP' })
      end

      local open_telescope = function(builtin_fn_name)
        local ok, builtin = pcall(require, 'telescope.builtin')
        if not ok then
          return false
        end

        local fn = builtin[builtin_fn_name]
        if type(fn) ~= 'function' then
          return false
        end

        fn()
        return true
      end

      local encoding = client.offset_encoding or 'utf-16'

      local jump_to = function(location)
        vim.lsp.util.show_document(location, encoding, { focus = true })
      end

      local goto_definition = function()
        if not client:supports_method 'textDocument/definition' then
          notify('This LSP does not support go-to-definition', vim.log.levels.WARN)
          return
        end

        local params = vim.lsp.util.make_position_params(0, encoding)

        client:request('textDocument/definition', params, function(err, result, _ctx, _)
          if err then
            notify(('Definition request failed: %s'):format(err.message or tostring(err)), vim.log.levels.ERROR)
            return
          end

          if not result or vim.tbl_isempty(is_list(result) and result or { result }) then
            notify 'No definition found'
            return
          end

          local locations = is_list(result) and result or { result }

          if #locations == 1 then
            jump_to(locations[1])
            return
          end

          -- Multiple definitions: prefer telescope, fall back to native.
          if not open_telescope 'lsp_definitions' then
            vim.lsp.buf.definition()
          end
        end, bufnr)
      end

      local goto_source_definition = function()
        if not client:supports_method 'workspace/executeCommand' then
          notify('LSP does not support executeCommand', vim.log.levels.WARN)
          goto_definition()
          return
        end

        local commands = (client.server_capabilities.executeCommandProvider or {}).commands or {}
        local command = nil
        if vim.tbl_contains(commands, 'typescript.goToSourceDefinition') then
          command = 'typescript.goToSourceDefinition'
        elseif vim.tbl_contains(commands, '_typescript.goToSourceDefinition') then
          command = '_typescript.goToSourceDefinition'
        end

        if not command then
          notify('TypeScript go-to-source-definition not advertised by server', vim.log.levels.WARN)
          goto_definition()
          return
        end

        local params = vim.lsp.util.make_position_params(0, encoding)
        local arguments = { params.textDocument.uri, params.position }

        client:request('workspace/executeCommand', { command = command, arguments = arguments }, function(err, result, _ctx, _)
          if err then
            notify(('Source definition failed: %s'):format(err.message or tostring(err)), vim.log.levels.ERROR)
            goto_definition()
            return
          end

          if not result or vim.tbl_isempty(is_list(result) and result or { result }) then
            notify 'No source definition found'
            goto_definition()
            return
          end

          local locations = is_list(result) and result or { result }

          if #locations == 1 then
            jump_to(locations[1])
            return
          end

          local items = vim.lsp.util.locations_to_items(locations, encoding)
          vim.fn.setqflist({}, 'r', { title = 'LSP source definitions', items = items })
          vim.cmd 'copen'
        end, bufnr)
      end

      -- set keybinds
      opts.desc = 'Show LSP references'
      keymap.set('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts) -- show definition, references

      opts.desc = 'Go to declaration'
      keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- go to declaration

      opts.desc = 'Go to definition'
      keymap.set('n', 'gd', goto_definition, opts)

      opts.desc = 'Show LSP definitions'
      keymap.set('n', '<leader>gd', '<cmd>Telescope lsp_definitions<CR>', opts)

      if client.name == 'vtsls' or client.name == 'ts_ls' then
        opts.desc = 'Go to source definition (TypeScript)'
        keymap.set('n', 'gS', goto_source_definition, opts)
      end

      opts.desc = 'Show LSP implementations'
      keymap.set('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts) -- show lsp implementations

      opts.desc = 'Show LSP type definitions'
      keymap.set('n', 'gt', '<cmd>Telescope lsp_type_definitions<CR>', opts) -- show lsp type definitions

      opts.desc = 'See available code actions'
      keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

      opts.desc = 'Smart rename'
      keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- smart rename

      opts.desc = 'Show buffer diagnostics'
      keymap.set('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', opts) -- show  diagnostics for file

      opts.desc = 'Show line diagnostics'
      keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts) -- show diagnostics for line

      opts.desc = 'Go to previous diagnostic (warn+)'
      keymap.set('n', '[d', function()
        vim.diagnostic.goto_prev { severity = { min = vim.diagnostic.severity.WARN } }
      end, opts)

      opts.desc = 'Go to next diagnostic (warn+)'
      keymap.set('n', ']d', function()
        vim.diagnostic.goto_next { severity = { min = vim.diagnostic.severity.WARN } }
      end, opts)

      opts.desc = 'Go to previous error'
      keymap.set('n', '[e', function()
        vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
      end, opts)

      opts.desc = 'Go to next error'
      keymap.set('n', ']e', function()
        vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
      end, opts)

      opts.desc = 'Show documentation for what is under cursor'
      keymap.set('n', 'K', vim.lsp.buf.hover, opts)

      opts.desc = 'Search workspace symbols'
      vim.keymap.set('n', '<leader>st', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', opts)

      opts.desc = 'Restart LSP'
      keymap.set('n', '<leader>rs', ':LspRestart<CR>', opts) -- mapping to restart lsp if necessary

      -- Configure actions on save
      -- vim.api.nvim_create_autocmd("BufWritePre", {
      --   group = vim.api.nvim_create_augroup("Format", { clear = true }),
      --   callback = function()
      --     local ts = require("typescript").actions
      --     ts.addMissingImports({ async = true })
      --     ts.organizeImports({ async = true })
      --     vim.lsp.buf.format({ async = true })
      --   end,
      -- }, opts)
    end

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = ' ', Warn = ' ', Hint = '󰠠 ', Info = ' ' }
    for type, icon in pairs(signs) do
      local hl = 'DiagnosticSign' .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
    end

    -- configure html server
    lspconfig['html'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- TypeScript/JavaScript via ts_ls (typescript-language-server, instalado vía npm):
    -- root_dir: prefer repo root so one ts_ls instance indexes the whole monorepo; ts_ls
    -- picks the right tsconfig per file. Fall back to nearest package tsconfig otherwise.
    -- Binary: ~/.nvm/versions/node/*/bin/typescript-language-server
    -- If go-to-definition fails, run :LspInfo in a TS file to confirm ts_ls is attached.
    local ts_inlay_hints = {
      includeInlayParameterNameHints = 'all',
      parameterNameHintsPrefix = ' ',
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    }

    lspconfig['ts_ls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      root_dir = function(fname)
        return util.root_pattern('nx.json', 'pnpm-workspace.yaml', 'lerna.json')(fname)
          or util.root_pattern('tsconfig.json', 'jsconfig.json', 'package.json')(fname)
          or util.root_pattern('.git')(fname)
      end,
      init_options = {
        hostInfo = 'neovim',
        -- 16 GB (in MB) for huge huge NX monorepos
        maxTsServerMemory = 16000,
        preferences = {
          -- Lazy-load referenced projects for better startup/indexing
          lazyConfiguredProjectsFromExternalProject = true,
          includePackageJsonAutoImports = 'auto',
        },
      },
      settings = {
        typescript = {
          updateImportsOnFileMove = { enabled = 'always' },
          suggest = { completeFunctionCalls = true },
          inlayHints = ts_inlay_hints,
        },
        javascript = {
          updateImportsOnFileMove = { enabled = 'always' },
          suggest = { completeFunctionCalls = true },
          inlayHints = ts_inlay_hints,
        },
      },
    }

    -- configure css server
    lspconfig['cssls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- configure tailwindcss server
    lspconfig['tailwindcss'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = {
        'aspnetcorerazor',
        'astro',
        'astro-markdown',
        'blade',
        'django-html',
        'edge',
        'eelixir',
        'ejs',
        'erb',
        'eruby',
        'gohtml',
        'haml',
        'handlebars',
        'hbs',
        'html',
        'html-eex',
        'heex',
        'jade',
        'leaf',
        'liquid',
        'mdx',
        'mustache',
        'njk',
        'nunjucks',
        'razor',
        'slim',
        'twig',
        'css',
        'less',
        'postcss',
        'sass',
        'scss',
        'stylus',
        'sugarss',
        'javascriptreact',
        'reason',
        'rescript',
        'typescriptreact',
        'vue',
        'svelte',
      },
    }

    -- configure svelte server
    lspconfig['svelte'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- configure prisma orm server
    lspconfig['prismals'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }


    -- configure emmet language server
    lspconfig['emmet_ls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'svelte' },
    }

    -- configure python server
    lspconfig['pyright'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- configure json-lsp server
    lspconfig['jsonls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- configure terraform-ls server
    lspconfig['terraformls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    lspconfig['csharp_ls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    -- configure lua server (with special settings)
    lspconfig['lua_ls'].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = { -- custom settings for lua
        Lua = {
          -- make the language server recognize "vim" global
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            -- make language server aware of runtime files
            library = {
              [vim.fn.expand '$VIMRUNTIME/lua'] = true,
              [vim.fn.stdpath 'config' .. '/lua'] = true,
            },
          },
        },
      },
    }
  end,
}
