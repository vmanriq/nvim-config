return {
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>gwl",
        function() require("telescope").extensions.git_worktree.git_worktrees() end,
        desc = "Worktrees: list / switch",
      },
      {
        "<leader>gwc",
        function() require("telescope").extensions.git_worktree.create_git_worktree() end,
        desc = "Worktrees: create",
      },
      {
        "<leader>gwD",
        "<cmd>WorktreeDashboard<cr>",
        desc = "Worktrees: dashboard",
      },
      { "<leader>gwd", "<cmd>DiffviewOpen<cr>",            desc = "Worktree: diff (DiffviewOpen)" },
      { "<leader>gwp", "<cmd>!wt-pr<cr>",                  desc = "Worktree: push + draft PR" },
      { "<leader>gws", "<cmd>!wt-status<cr>",              desc = "Worktree: status (shell)" },
    },
    config = function()
      local worktree = require("git-worktree")
      worktree.setup({
        change_directory_command = "cd",
        update_on_change = true,
        clearjumps_on_change = true,
        autopush = false,
      })

      worktree.on_tree_change(function(op, _meta)
        if op == worktree.Operations.Switch then
          vim.cmd("silent! %bwipeout!")
          vim.cmd("LspRestart")
          pcall(function() require("gitsigns").refresh() end)
        end
      end)

      require("telescope").load_extension("git_worktree")
    end,
  },
  {
    name = "worktree-dashboard",
    dir = vim.fn.stdpath("config") .. "/lua/custom/worktree-dashboard",
    cmd = "WorktreeDashboard",
    config = function() require("custom.worktree-dashboard").setup() end,
  },
}
