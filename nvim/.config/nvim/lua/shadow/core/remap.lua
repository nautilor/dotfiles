local keymap = vim.keymap
local opts = { remap = true, silent = true }
local nopts = { noremap = true, silent = true }
local function smart_close()
	if #vim.api.nvim_list_wins() > 1 then
		vim.cmd("close")
	else
		vim.cmd("bd!")
	end
end

-- Remap space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

keymap.set({ "x", "n", "i" }, "<C-k>", "<C-o>", nopts)

-- center movement
keymap.set("n", "j", "jzz", opts)
keymap.set("n", "k", "kzz", opts)

-- Disable F1 & q
keymap.set("n", "q", "")
keymap.set({ "n", "i" }, "<F1>", "")

-- Terminal esc key
keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- Better paste without overwriting clipboard
keymap.set("x", "p", '"_dP')
keymap.set({ "n", "v" }, "x", '"_x', nopts)

-- System clipboard
keymap.set({ "n", "x" }, "<C-y>", '"+y', nopts)
keymap.set("n", "<C-p>", "\"+p", nopts)
keymap.set("v", "<C-p>", '"_d"+P', nopts)
keymap.set("x", "<C-p>", '"_d"+P', nopts)

-- Save
keymap.set("n", "<C-s>", ":w<Return>")
keymap.set("i", "<C-s>", "<Esc>:w<Return>a")
keymap.set("v", "<C-s>", "<Esc>:w<Return>gv")

-- Quit insert mode quickly
keymap.set("i", "jj", "<Esc>")

-- Close buffer/window
keymap.set("n", "<leader>q", ":q<Return>", nopts)
keymap.set("n", "<leader>!", ":q!<Return>", nopts)
keymap.set("n", "<leader>1", ":q!<Return>", nopts)
keymap.set("n", "<C-w>c", smart_close, nopts)

-- Move X lines when using shift+down/up
keymap.set({ "n", "v" }, "<S-Down>", "3j", nopts)
keymap.set({ "n", "v" }, "<S-Up>", "3k", nopts)

-- Comment code
keymap.set("x", "<C-_>", "gc", opts)
keymap.set("n", "<C-_>", "gcc", opts)
keymap.set("n", "<C-/>", "gcc", opts)
keymap.set("x", "<C-/>", "gc", opts)
keymap.set({ "n", "x" }, "<C-k>", function() require("fold_imports").toggle() end, opts)

-- Tabs
keymap.set("n", "<tab>", ":bnext<Return>", nopts)
keymap.set("n", "<S-tab>", ":bprev<Return>", nopts)
keymap.set("n", "<leader>bd", ":bd!<Return>", nopts)

-- Reset the last search highlight
keymap.set("n", "<leader>/", ":nohlsearch<Return>", nopts)

-- Code Diff current File
keymap.set("n", "<leader>gd", ":CodeDiff file HEAD<Return>", nopts)

-- Split
keymap.set("n", "sv", ":split<Return>", nopts)
keymap.set("n", "ss", ":vsplit<Return>", nopts)
keymap.set("n", "sd", smart_close, nopts)
keymap.set("n", "sk", ":bp | bd #<Return>", nopts)

-- Diagnostic
keymap.set("n", "<C-j>", vim.diagnostic.goto_next, nopts)

-- LazyGit
keymap.set("n", "<C-l>", ":LazyGit<Return>", nopts)

-- Snacks Picker
keymap.set({ "i", "n" }, "<C-o>", function() require("snacks").picker.files() end, nopts)
keymap.set({ "i", "n" }, "<C-f>", function() require("snacks").picker.grep({ toggle = true }) end, nopts)
keymap.set({ "i", "n" }, "<C-b>", function() require("snacks").picker.buffers({ toggle = true }) end, nopts)

-- LSP
keymap.set("n", "gd", function() require("snacks").picker.lsp_definitions() end, nopts)
keymap.set("n", "gf", function() require("snacks").picker.lsp_references() end, nopts)
keymap.set("n", "<leader>r", vim.lsp.buf.rename)
keymap.set({ "n", "i" }, "<F2>", vim.lsp.buf.rename)

-- Snacks Zen
keymap.set("n", "<C-z>", function() require("snacks").zen() end, nopts)

-- File Explorer
keymap.set("n", "<leader>e", function() require("snacks").picker.explorer() end, nopts)

-- Terminal
keymap.set({ "n", "x", "t", "i" }, "<C-t>", function() require("snacks").terminal.toggle() end, nopts)


-- Obsidian
keymap.set("n", "<leader>os", ":Obsidian quick_switch<CR>")
keymap.set("n", "<leader>on", ":Obsidian new<CR>")
keymap.set("n", "<leader>oo", ":cd ~/.obsidian/Notes/<CR>")
vim.api.nvim_create_autocmd("User", {
	pattern = "ObsidianNoteEnter",
	callback = function()
		keymap.set("n", "<leader>oc", ":Obsidian toggle_checkbox<CR>")
	end
})
