-- AWS SSO credential helper.
-- :AwsCheck [profile]  — validate credentials (all profiles or one)
-- :AwsLogin [profile]  — run `aws sso login` in a floating terminal
-- Loaded from init.lua via require('custom.aws').setup()

local M = {}

M.config = {
  -- Fallback if ~/.aws/config can't be read
  profiles = { 'dev', 'dev2', 'staging', 'prod' },
  timeout_ms = 8000,
}

local function parse_profiles()
  local path = vim.fn.expand '~/.aws/config'
  if vim.fn.filereadable(path) ~= 1 then
    return M.config.profiles
  end
  local profiles = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local name = line:match '^%[profile%s+(.-)%]'
    if name then
      table.insert(profiles, name)
    end
  end
  return #profiles > 0 and profiles or M.config.profiles
end

-- cb(result) where result = { profile, ok, expired, detail }
local function check_profile(profile, cb)
  vim.system(
    { 'aws', 'sts', 'get-caller-identity', '--profile', profile, '--output', 'json' },
    { timeout = M.config.timeout_ms },
    function(out)
      local result = { profile = profile, ok = out.code == 0, expired = false, detail = '' }
      if result.ok then
        local decoded = vim.json.decode(out.stdout or '{}')
        local role = (decoded.Arn or ''):match 'assumed%-role/([^/]+)' or decoded.Arn or '?'
        result.detail = string.format('%s (%s)', decoded.Account or '?', role)
      elseif out.code == 124 then
        result.detail = 'timeout — ¿red caída o perfil mal configurado?'
      else
        local err = (out.stderr or ''):gsub('%s+', ' '):gsub('^%s', ''):sub(1, 120)
        result.expired = err:lower():match 'expired' ~= nil or err:match 'SSO' ~= nil
        result.detail = err
      end
      cb(result)
    end
  )
end

local function sso_login(profile)
  local cmd = 'aws sso login --profile ' .. profile
  local ok_toggleterm, terminal = pcall(require, 'toggleterm.terminal')
  if ok_toggleterm then
    terminal.Terminal:new({ cmd = cmd, direction = 'float', close_on_exit = false }):toggle()
  else
    vim.cmd('botright split | terminal ' .. cmd)
  end
end

local function render_summary(results)
  local lines, expired = {}, {}
  for _, r in ipairs(results) do
    if r.ok then
      table.insert(lines, string.format('✓ %-10s %s', r.profile, r.detail))
    else
      table.insert(lines, string.format('✗ %-10s %s', r.profile, r.expired and 'EXPIRED — ' .. r.detail or r.detail))
      if r.expired then
        table.insert(expired, r.profile)
      end
    end
  end
  vim.notify(table.concat(lines, '\n'), #expired > 0 and vim.log.levels.WARN or vim.log.levels.INFO, { title = 'AWS' })
  if #expired > 0 then
    vim.ui.select(expired, { prompt = 'SSO expirado — login con perfil:' }, function(choice)
      if choice then
        sso_login(choice)
      end
    end)
  end
end

function M.check(profile)
  vim.notify('Chequeando perfil ' .. profile .. '…', vim.log.levels.INFO, { title = 'AWS' })
  check_profile(profile, function(result)
    vim.schedule(function()
      render_summary { result }
    end)
  end)
end

function M.check_all()
  local profiles = parse_profiles()
  vim.notify('Chequeando ' .. #profiles .. ' perfiles…', vim.log.levels.INFO, { title = 'AWS' })
  local results, pending = {}, #profiles
  for i, profile in ipairs(profiles) do
    check_profile(profile, function(result)
      results[i] = result
      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          render_summary(results)
        end)
      end
    end)
  end
end

function M.login(profile)
  if profile then
    return sso_login(profile)
  end
  vim.ui.select(parse_profiles(), { prompt = 'aws sso login — perfil:' }, function(choice)
    if choice then
      sso_login(choice)
    end
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  if vim.fn.executable 'aws' ~= 1 then
    vim.notify('aws CLI no encontrado — :AwsCheck deshabilitado', vim.log.levels.WARN, { title = 'AWS' })
    return
  end

  local complete = function()
    return parse_profiles()
  end

  vim.api.nvim_create_user_command('AwsCheck', function(cmd)
    if cmd.args ~= '' then
      M.check(cmd.args)
    else
      M.check_all()
    end
  end, { nargs = '?', complete = complete, desc = 'Validar credenciales AWS SSO' })

  vim.api.nvim_create_user_command('AwsLogin', function(cmd)
    M.login(cmd.args ~= '' and cmd.args or nil)
  end, { nargs = '?', complete = complete, desc = 'aws sso login' })

  vim.keymap.set('n', '<leader>awc', M.check_all, { desc = 'A[W]S [C]heck credentials' })
  vim.keymap.set('n', '<leader>awl', function()
    M.login()
  end, { desc = 'A[W]S SSO [L]ogin' })
end

return M
