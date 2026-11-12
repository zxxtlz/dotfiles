-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Yank/paste straight through to the system clipboard. Neovim finds
-- wl-copy/wl-paste on Wayland by itself, so no provider config is needed
-- here (plain vim gets the same thing through ~/.vimrc).
vim.opt.clipboard = "unnamedplus"
