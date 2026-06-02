-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.lazyvim_picker = "telescope"
vim.opt.spelllang = { "ru", "en" }

-- Copy to system clipboard via wl-copy (Wayland/Hyprland)
vim.opt.clipboard = "unnamedplus"
