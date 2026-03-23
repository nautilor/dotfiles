local is_latex_compiler_enabled = true

local function latex_compile()
	-- check if the compiler is enabled
	if not is_latex_compiler_enabled then
		return
	end
	-- get the current file and the pdf file
	local current_file = vim.fn.expand('%:p')
	local pdf_file = vim.fn.expand('%:p:r') .. '.pdf'

	-- create an autocmd to compile the file after saving it
	vim.api.nvim_create_autocmd('BufWritePost', { pattern = { '*.tex' }, callback = latex_compile })

	-- we use latexmk to compile the file
	local compile_cmd = 'latexmk -pdf -interaction=nonstopmode -silent ' .. current_file
	local handle = io.popen(compile_cmd .. ' 2>&1')
	if (handle == nil) then
		vim.api.nvim_err_writeln("Errore di compilazione: " .. compile_cmd)
		return
	end
	local result = handle:read('*a')
	handle:close()

	if result:match("error") then
		vim.api.nvim_err_writeln("Errore di compilazione:\n" .. result)
	end

	-- open the pdf file with mupdf
	local mupdf_cmd = 'mupdf ' .. pdf_file .. ' &'
	local mupdf_pid = vim.fn.system('pgrep -f "mupdf ' .. pdf_file .. '"')

	-- if mupdf is not running open the pdf file
	-- otherwise send a HUP signal to reload the file
	if mupdf_pid == '' then
		vim.fn.system(mupdf_cmd)
	else
		vim.fn.system('pkill -HUP mupdf')
	end
end

-- if enabled compile the tex file when opening it
vim.api.nvim_create_autocmd('BufEnter', {
	pattern = '*.tex',
	callback = function()
		if is_latex_compiler_enabled then
			latex_compile()
		end
	end,
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
