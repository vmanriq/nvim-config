-- Worktree dashboard: scratch buffer showing all git worktrees for the current
-- repo plus their branch, dirty state, last Claude session activity, and PR state.
-- Keymaps on the buffer:
--   <CR>  switch to the selected worktree (via git-worktree.nvim)
--   p     push + draft PR  (:!wt-pr <name>)
--   d     remove worktree  (:!wt-rm <name>)
--   r     resume claude    (:!wt-resume <name> in a split terminal)
--   s     DiffviewOpen on the selected worktree
--   R     refresh
--   q     close

local M = {}

local BUFNAME = "worktree-dashboard"
local REFRESH_INTERVAL_MS = 5000

local state = {
  bufnr = nil,
  rows = {},
  timer = nil,
  main_path = nil,
}

local function shell(command)
  local handle = io.popen(command)
  if not handle then return "" end
  local output = handle:read("*a") or ""
  handle:close()
  return output
end

local function main_worktree()
  local first = shell("git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }'")
  return vim.fn.trim(first)
end

local function encode_path(path)
  return "-" .. path:gsub("^/", ""):gsub("[^%w]", "-")
end

local function last_activity(worktree_path)
  local dir = vim.fn.expand("~/.claude/projects/" .. encode_path(worktree_path))
  if vim.fn.isdirectory(dir) == 0 then return nil end
  local listing = shell(string.format("ls -t %q/*.jsonl 2>/dev/null | head -1", dir))
  local newest = vim.fn.trim(listing)
  if newest == "" then return nil end
  local stat = vim.uv.fs_stat(newest)
  return stat and stat.mtime.sec or nil
end

local function relative_age(epoch)
  if not epoch then return "—" end
  local diff = os.time() - epoch
  if diff < 60 then return diff .. "s ago" end
  if diff < 3600 then return math.floor(diff / 60) .. "m ago" end
  if diff < 86400 then return math.floor(diff / 3600) .. "h ago" end
  return math.floor(diff / 86400) .. "d ago"
end

local function repo_slug(main_path)
  local origin = vim.fn.trim(shell(string.format("git -C %q config --get remote.origin.url 2>/dev/null", main_path)))
  return origin:match("github%.com[:/](.-/[^/.]+)") or origin:match("github%.com[:/](.-/[^.]+)") or ""
end

local pr_cache = { stamp = 0, data = {} }
local function pr_state(slug, branch)
  if slug == "" or branch == "-" then return "—" end
  local now = os.time()
  if now - pr_cache.stamp > 30 then pr_cache = { stamp = now, data = {} } end
  local key = slug .. "/" .. branch
  if pr_cache.data[key] then return pr_cache.data[key] end
  local output = shell(string.format(
    "gh -R %s pr list --head %s --json number,state,isDraft --limit 1 2>/dev/null",
    vim.fn.shellescape(slug), vim.fn.shellescape(branch)))
  local ok, parsed = pcall(vim.json.decode, output)
  if not ok or type(parsed) ~= "table" or #parsed == 0 then
    pr_cache.data[key] = "—"
    return "—"
  end
  local pr = parsed[1]
  local suffix = pr.isDraft and " (draft)" or ""
  local value = string.format("#%d %s%s", pr.number, pr.state, suffix)
  pr_cache.data[key] = value
  return value
end

local function collect_rows()
  local main = main_worktree()
  if main == "" then return {}, "" end
  state.main_path = main
  local slug = repo_slug(main)

  local porcelain = shell("git worktree list --porcelain 2>/dev/null")
  local entries = {}
  local current = {}
  for line in porcelain:gmatch("[^\n]+") do
    if line:match("^worktree ") then
      if current.path then table.insert(entries, current) end
      current = { path = line:sub(10), branch = "-" }
    elseif line:match("^branch ") then
      current.branch = line:sub(15)
    elseif line:match("^detached") then
      current.branch = "-"
    end
  end
  if current.path then table.insert(entries, current) end

  local rows = {}
  for _, entry in ipairs(entries) do
    local name = entry.path == main and "(main)" or entry.path:match("([^/]+)$")
    local dirty_output = shell(string.format("git -C %q status --porcelain 2>/dev/null", entry.path))
    local dirty = vim.fn.trim(dirty_output) ~= "" and "*" or "-"
    local activity = relative_age(last_activity(entry.path))
    local pr = pr_state(slug, entry.branch)
    table.insert(rows, {
      name = name,
      path = entry.path,
      branch = entry.branch,
      dirty = dirty,
      activity = activity,
      pr = pr,
    })
  end
  return rows, slug
end

local function render(bufnr, rows)
  local lines = {
    string.format("%-22s  %-32s  %-5s  %-14s  %s", "NAME", "BRANCH", "DIRTY", "LAST CLAUDE", "PR"),
    string.rep("─", 90),
  }
  for _, row in ipairs(rows) do
    table.insert(lines, string.format(
      "%-22s  %-32s  %-5s  %-14s  %s",
      row.name, row.branch, row.dirty, row.activity, row.pr))
  end
  table.insert(lines, "")
  table.insert(lines, "<CR> switch · p draft PR · d remove · r resume · s diff · R refresh · q close")
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

local function refresh()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then return end
  local rows = collect_rows()
  state.rows = rows
  render(state.bufnr, rows)
end

local function row_under_cursor()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local index = lnum - 2
  return state.rows[index]
end

local function switch_to(row)
  if not row then return end
  pcall(function() require("git-worktree").switch_worktree(row.path) end)
end

local function open_dashboard()
  local existing = vim.fn.bufnr(BUFNAME)
  if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
    vim.api.nvim_set_current_buf(existing)
    state.bufnr = existing
    refresh()
    return
  end

  vim.cmd("enew")
  local bufnr = vim.api.nvim_get_current_buf()
  state.bufnr = bufnr
  vim.api.nvim_buf_set_name(bufnr, BUFNAME)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "worktree-dashboard"

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, nowait = true, desc = desc })
  end

  map("<CR>", function() switch_to(row_under_cursor()) end, "Worktree: switch")
  map("p", function()
    local row = row_under_cursor()
    if not row or row.name == "(main)" then return end
    vim.cmd(string.format("!wt-pr %s", vim.fn.shellescape(row.name)))
  end, "Worktree: push + draft PR")
  map("d", function()
    local row = row_under_cursor()
    if not row or row.name == "(main)" then return end
    vim.cmd(string.format("!wt-rm %s", vim.fn.shellescape(row.name)))
    refresh()
  end, "Worktree: remove")
  map("r", function()
    local row = row_under_cursor()
    if not row or row.name == "(main)" then return end
    vim.cmd("botright split | resize 15 | terminal wt-resume " .. vim.fn.shellescape(row.name))
  end, "Worktree: resume claude")
  map("s", function()
    local row = row_under_cursor()
    if not row then return end
    switch_to(row)
    vim.cmd("DiffviewOpen")
  end, "Worktree: switch + diff")
  map("R", refresh, "Worktree: refresh")
  map("q", "<cmd>bwipeout<cr>", "Worktree: close dashboard")

  refresh()

  if state.timer then state.timer:stop(); state.timer:close() end
  state.timer = vim.uv.new_timer()
  state.timer:start(REFRESH_INTERVAL_MS, REFRESH_INTERVAL_MS, vim.schedule_wrap(function()
    if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) and vim.fn.bufwinid(state.bufnr) ~= -1 then
      refresh()
    end
  end))

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function()
      if state.timer then state.timer:stop(); state.timer:close(); state.timer = nil end
      state.bufnr = nil
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("WorktreeDashboard", open_dashboard, {})
end

return M
