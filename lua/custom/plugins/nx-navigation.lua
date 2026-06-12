local function get_nx_projects()
  local projects = {}
  local search_dirs = { 'apps', 'libs', 'packages' }

  for _, dir in ipairs(search_dirs) do
    local path = vim.fn.getcwd() .. '/' .. dir
    if vim.fn.isdirectory(path) == 1 then
      local entries = vim.fn.readdir(path)
      for _, entry in ipairs(entries) do
        local full = path .. '/' .. entry
        if vim.fn.isdirectory(full) == 1 then
          table.insert(projects, { name = entry, path = full, group = dir })
        end
      end
    end
  end

  table.sort(projects, function(a, b)
    if a.group == b.group then
      return a.name < b.name
    end
    return a.group < b.group
  end)

  return projects
end

local function pick_project_then(callback)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local projects = get_nx_projects()

  pickers
    .new({}, {
      prompt_title = 'Pick Nx Project',
      finder = finders.new_table {
        results = projects,
        entry_maker = function(entry)
          local display = entry.group .. '/' .. entry.name
          return {
            value = entry,
            display = display,
            ordinal = display,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            callback(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

local function find_current_project_root()
  local project_root = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  local root = project_root

  while root ~= '/' do
    if vim.fn.filereadable(root .. '/project.json') == 1 or vim.fn.filereadable(root .. '/package.json') == 1 then
      return root
    end
    root = vim.fn.fnamemodify(root, ':h')
  end

  return project_root
end

return {
  'nvim-telescope/telescope.nvim',
  keys = {
    {
      '<leader>sp',
      function()
        pick_project_then(function(project)
          require('telescope.builtin').find_files {
            prompt_title = 'Files in ' .. project.group .. '/' .. project.name,
            cwd = project.path,
          }
        end)
      end,
      desc = '[S]earch Nx [P]roject (pick then find files)',
    },
    {
      '<leader>sP',
      function()
        pick_project_then(function(project)
          require('telescope.builtin').live_grep {
            prompt_title = 'Grep in ' .. project.group .. '/' .. project.name,
            cwd = project.path,
          }
        end)
      end,
      desc = '[S]earch Nx [P]roject (pick then grep)',
    },
    {
      '<leader>sa',
      function()
        require('telescope.builtin').find_files {
          prompt_title = 'Files in current Nx project',
          cwd = find_current_project_root(),
        }
      end,
      desc = '[S]earch in current [A]pp/lib',
    },
    {
      '<leader>sG',
      function()
        require('telescope.builtin').live_grep {
          prompt_title = 'Grep in current Nx project',
          cwd = find_current_project_root(),
        }
      end,
      desc = '[S]earch [G]rep in current app/lib',
    },
  },
}
