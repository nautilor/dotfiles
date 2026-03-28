local is_latex_compiler_enabled = true
local latex_augroup = vim.api.nvim_create_augroup("latex_compile", { clear = true })

local function latex_compile()
	if not is_latex_compiler_enabled then return end

	local current_file = vim.fn.expand('%:p')
	local pdf_file = vim.fn.expand('%:p:r') .. '.pdf'

	local compile_cmd = 'latexmk -pdf -interaction=nonstopmode -silent ' .. current_file
	local handle = io.popen(compile_cmd .. ' 2>&1')
	if handle == nil then
		vim.api.nvim_err_writeln("Errore di compilazione: " .. compile_cmd)
		return
	end
	local result = handle:read('*a')
	handle:close()

	if result:match("error") then
		vim.api.nvim_err_writeln("Errore di compilazione:\n" .. result)
	end

	local mupdf_cmd = 'mupdf ' .. pdf_file .. ' &'
	local mupdf_pid = vim.fn.system('pgrep -f "mupdf ' .. pdf_file .. '"')

	if mupdf_pid == '' then
		vim.fn.system(mupdf_cmd)
	else
		vim.fn.system('pkill -HUP mupdf')
	end
end

vim.api.nvim_create_autocmd('BufEnter', {
	group = latex_augroup,
	pattern = '*.tex',
	callback = function()
		if is_latex_compiler_enabled then latex_compile() end
	end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
	group = latex_augroup,
	pattern = { '*.tex' },
	callback = latex_compile,
})

-- toggle the latex compiler and compile the file if enabled
local function toggle_latex_compiler()
	is_latex_compiler_enabled = not is_latex_compiler_enabled
	if is_latex_compiler_enabled then
		latex_compile()
	end
end

-- keymap to toggle the latex compiler
local keymap = vim.keymap
local opts = { noremap = true, silent = true }
keymap.set("n", "<leader>lc", toggle_latex_compiler, opts)
