-- Basic Neovim configuration override

vim.wo.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.conceallevel = 1
vim.opt.cmdheight = 0
vim.opt.list = true
vim.opt.listchars = { tab = " ", trail = "·", extends = "", precedes = "", nbsp = "○" }
vim.fn.matchadd("ErrorMsg", [[\s\+$]])
