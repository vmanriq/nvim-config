-- ~/.config/nvim/cursor.lua
-- Config standalone para la extensión vim de Cursor (no la carga init.lua).
-- Basic Vim feel
vim.o.relativenumber = true
vim.o.number = true
vim.o.scrolloff = 5
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"

-- Keymaps inside Cursor + Neovim
vim.keymap.set("n", "<C-s>", ":w<CR>")
vim.keymap.set("n", "<C-q>", ":q<CR>")
vim.keymap.set("n", "<leader>ff", ":Files<CR>")

-- Disable UI plugins that conflict with Cursor
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)
-- set clipboard=unnamedplus
