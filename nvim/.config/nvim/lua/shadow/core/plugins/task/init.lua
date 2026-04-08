-- Minimal task manager for .task.md files.
-- One file per git project: a title line and a flat checkbox list.

local M = {}

local config = {
	filename = ".task.md",
	keys = {
		open   = "<leader>tf",
		toggle = "<CR>",
		cycle  = "<Tab>",
		add    = "o",
		above  = "O",
		delete = "dd",
	},
}

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------

local function find_git_root()
	local path = vim.fn.expand("%:p:h")
	local out  = vim.fn.systemlist(
		"git -C " .. vim.fn.shellescape(path) .. " rev-parse --show-toplevel 2>/dev/null"
	)
	return (vim.v.shell_error == 0 and #out > 0) and out[1] or nil
end

local function project_name(root)
	return vim.fn.fnamemodify(root, ":t")
end

local function is_task_buf(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr or 0)
	return name:sub(- #config.filename) == config.filename
end

local function get_state(line)
	return line:match("^%s*%- %[(.-)%]")
end

local function set_state(line, state)
	return (line:gsub("^(%s*%- %[)(.-)(%])", "%1" .. state .. "%3", 1))
end

local cycle_states = { " ", "-", "x" }

local function next_state(current)
	for i, s in ipairs(cycle_states) do
		if s == current then
			return cycle_states[(i % #cycle_states) + 1]
		end
	end
	return " "
end

----------------------------------------------------------------------
-- actions
----------------------------------------------------------------------

local function toggle()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local state = get_state(line)
	if not state then return end
	local new = state == "x" and " " or "x"
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { set_state(line, new) })
end

local function toggle_visual()
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
		"x",
		false
	)

	local r1, r2  = vim.fn.line("'<"), vim.fn.line("'>")
	local lines   = vim.api.nvim_buf_get_lines(0, r1 - 1, r2, false)

	local pending = 0
	for _, l in ipairs(lines) do
		local s = get_state(l)
		if s and s ~= "x" then pending = pending + 1 end
	end

	local target = pending > 0 and "x" or " "

	for i, l in ipairs(lines) do
		if get_state(l) then
			lines[i] = set_state(l, target)
		end
	end

	vim.api.nvim_buf_set_lines(0, r1 - 1, r2, false, lines)
end

local function cycle()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local state = get_state(line)
	if not state then return end
	vim.api.nvim_buf_set_lines(
		0,
		lnum - 1,
		lnum,
		false,
		{ set_state(line, next_state(state)) }
	)
end

local function add_task(dir)
	local lnum   = vim.api.nvim_win_get_cursor(0)[1]
	local cur    = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
	local indent = get_state(cur) and cur:match("^(%s*)") or ""
	local new    = indent .. "- [ ] "

	local at     = dir == 1 and lnum or lnum - 1

	vim.api.nvim_buf_set_lines(0, at, at, false, { new })
	vim.api.nvim_win_set_cursor(0, { at + 1, #new })
	vim.cmd("startinsert!")
end

local function delete_task()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {})
end

----------------------------------------------------------------------
-- highlights
----------------------------------------------------------------------

local function setup_highlights()
	vim.api.nvim_set_hl(0, "TaskDone", { link = "Comment" })
	vim.api.nvim_set_hl(0, "TaskWip", { link = "WarningMsg" })
end

local function refresh_highlights(bufnr)
	local ns = vim.api.nvim_create_namespace("task_hl")

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		local s = get_state(line)
		local hl = s == "x" and "TaskDone"
				or s == "-" and "TaskWip"
				or nil

		if hl then
			vim.api.nvim_buf_add_highlight(bufnr, ns, hl, i - 1, 0, -1)
		end
	end
end

----------------------------------------------------------------------
-- open / create (EXPORTED)
----------------------------------------------------------------------

function M.open_task_file()
	local root = find_git_root() or vim.fn.getcwd()
	local path = root .. "/" .. config.filename

	if vim.fn.filereadable(path) == 0 then
		local f = io.open(path, "w")
		if f then
			f:write("# " .. project_name(root) .. "\n\n- [ ] \n")
			f:close()
		end
	end

	vim.cmd("edit " .. vim.fn.fnameescape(path))

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i, l in ipairs(lines) do
		if get_state(l) then
			vim.api.nvim_win_set_cursor(0, { i, #l })
			break
		end
	end
end

----------------------------------------------------------------------
-- buffer setup
----------------------------------------------------------------------

local function setup_keymaps(bufnr)
	local k = config.keys
	local opts = { buffer = bufnr, silent = true }

	local function smart_insert_start()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		local line = vim.api.nvim_get_current_line()

		-- match empty task line
		if line:match("^%s*%- %[ %] $") then
			-- move cursor to end of line (after "- [ ] ")
			vim.api.nvim_win_set_cursor(0, { row, #line })
			vim.cmd("startinsert!")
		end
		vim.cmd("startinsert")
	end

	local function smart_append()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		local line = vim.api.nvim_get_current_line()

		if line:match("^%s*%- %[ %] $") then
			vim.api.nvim_win_set_cursor(0, { row, #line })
		end

		vim.cmd("startinsert!")
	end

	vim.keymap.set("n", "i", smart_insert_start, { buffer = bufnr, silent = true })
	vim.keymap.set("n", "a", smart_append, { buffer = bufnr, silent = true })

	if k.toggle then
		vim.keymap.set("n", k.toggle, toggle, vim.tbl_extend("force", opts, { desc = "Task: toggle" }))
		vim.keymap.set("v", k.toggle, toggle_visual, vim.tbl_extend("force", opts, { desc = "Task: toggle selection" }))
	end

	if k.cycle then
		vim.keymap.set("n", k.cycle, cycle, vim.tbl_extend("force", opts, { desc = "Task: cycle" }))
	end

	if k.add then
		vim.keymap.set("n", k.add, function() add_task(1) end, vim.tbl_extend("force", opts, { desc = "Task: add below" }))
	end

	if k.above then
		vim.keymap.set("n", k.above, function() add_task(-1) end, vim.tbl_extend("force", opts, { desc = "Task: add above" }))
	end

	if k.delete then
		vim.keymap.set("n", k.delete, delete_task, vim.tbl_extend("force", opts, { desc = "Task: delete" }))
	end
end

----------------------------------------------------------------------
-- setup
----------------------------------------------------------------------

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	setup_highlights()

	-- global key to open task file
	vim.keymap.set("n", config.keys.open, function()
		M.open_task_file()
	end, { silent = true, desc = "Task: open file" })

	-- user command
	vim.api.nvim_create_user_command("Task", function()
		M.open_task_file()
	end, {})

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWinEnter" }, {
		pattern = { "*/" .. config.filename, config.filename },
		callback = function(ev)
			if not is_task_buf(ev.buf) then return end

			vim.bo[ev.buf].filetype = "markdown"
			vim.wo.conceallevel = 2
			vim.wo.concealcursor = "nc"

			setup_keymaps(ev.buf)
			refresh_highlights(ev.buf)

			-- autosave when esc is pressed
			vim.api.nvim_create_autocmd("InsertLeave", {
				buffer = ev.buf,
				callback = function()
					if vim.bo[ev.buf].modified then
						vim.cmd("silent write")
					end
				end,
			})
			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				buffer = ev.buf,
				callback = function()
					if vim.bo[ev.buf].modified then
						vim.cmd("silent write")
					end
					refresh_highlights(ev.buf)
				end,
			})
		end,
	})
end

return M
