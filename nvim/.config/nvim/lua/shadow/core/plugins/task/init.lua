-- Minimal task manager for .task.md files.
-- One file per git project: a title line and a flat checkbox list.

local M = {}

local config = {
	filename = ".task.md",
	keys = {
		open     = "<C-0>",
		annotate = "<leader>ta",
		toggle   = "<CR>",
		cycle    = "<Tab>",
		add      = "o",
		above    = "O",
		delete   = "dd",
		jump     = "gx",
	},
	float = {
		width = 0.7,
		height = 0.7,
		border = "solid",
		title_prefix = " Tasks - ",
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

local function task_path(root)
	return root .. "/" .. config.filename
end

local function is_task_buf(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr or 0)
	return name:sub(- #config.filename) == config.filename
end

local function task_root(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr or 0)
	if path == "" then return nil end
	return vim.fn.fnamemodify(path, ":h")
end

local function is_float_win(win)
	local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
	return ok and cfg.relative ~= ""
end

local function get_state(line)
	return line:match("^%s*%- %[(.-)%]")
end

local function set_state(line, state)
	return (line:gsub("^(%s*%- %[)(.-)(%])", "%1" .. state .. "%3", 1))
end

local cycle_states = { " ", "-", "x" }
local refresh_highlights

local function next_state(current)
	for i, s in ipairs(cycle_states) do
		if s == current then
			return cycle_states[(i % #cycle_states) + 1]
		end
	end
	return " "
end

local function ensure_task_file(root)
	local path = task_path(root)

	if vim.fn.filereadable(path) == 0 then
		local f = io.open(path, "w")
		if f then
			f:write("\n- [ ] \n")
			f:close()
		end
	end

	return path
end

local function focus_first_task_line(win, bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, l in ipairs(lines) do
		if get_state(l) then
			vim.api.nvim_win_set_cursor(win, { i, #l })
			return
		end
	end
end

local function float_title(root)
	return {
		{ config.float.title_prefix .. project_name(root) .. " ", "TaskFloatTitle" },
	}
end

local function float_layout(root)
	local width = math.max(40, math.floor(vim.o.columns * config.float.width))
	local height = math.max(8, math.floor(vim.o.lines * config.float.height))
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	return {
		relative = "editor",
		style = "minimal",
		border = config.float.border,
		title = float_title(root),
		title_pos = "center",
		width = width,
		height = height,
		col = col,
		row = row,
	}
end

local function parse_code_ref(line)
	local match_start, match_end, rel_path, start_line, end_line = line:find("%[%[code:([^:%]]+):(%d+)%-(%d+)%]%]")
	if not match_start then
		match_start, match_end, rel_path, start_line = line:find("%[%[code:([^:%]]+):(%d+)%]%]")
	end

	if not match_start then return nil end

	start_line = tonumber(start_line)
	end_line = tonumber(end_line) or start_line

	return {
		rel_path = rel_path,
		start_line = start_line,
		end_line = end_line,
		match_start = match_start,
		match_end = match_end,
	}
end

local function format_code_ref(path, line1, line2)
	if line2 and line2 ~= line1 then
		return string.format("[[code:%s:%d-%d]]", path, line1, line2)
	end

	return string.format("[[code:%s:%d]]", path, line1)
end

local function task_insert_index(lines)
	for i = #lines, 1, -1 do
		if lines[i]:match("%S") then
			return i + 1
		end
	end

	return #lines + 1
end

local function append_task_line(path, line)
	local bufnr = vim.fn.bufnr(path)

	if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local insert_at = task_insert_index(lines)
		vim.api.nvim_buf_set_lines(bufnr, insert_at - 1, insert_at - 1, false, { line })

		if vim.bo[bufnr].modified then
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("silent write")
			end)
		end

		refresh_highlights(bufnr)
		return
	end

	local lines = vim.fn.readfile(path)
	local insert_at = task_insert_index(lines)
	table.insert(lines, insert_at, line)
	vim.fn.writefile(lines, path)
end

local function code_ref_for_range(bufnr, root, line1, line2)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil, "Current buffer has no file"
	end

	local full_path = vim.fn.fnamemodify(name, ":p")
	local root_prefix = root .. "/"
	if full_path:sub(1, #root_prefix) ~= root_prefix then
		return nil, "Current file is outside project root"
	end

	return format_code_ref(full_path:sub(#root_prefix + 1), line1, line2)
end

local function resolve_annotation_text(opts, cb)
	if opts.text and opts.text ~= "" then
		cb(opts.text)
		return
	end

	vim.ui.input({ prompt = "Task note: " }, function(input)
		cb(input)
	end)
end

local function annotate_code(opts)
	local bufnr = opts.bufnr or 0
	if is_task_buf(bufnr) then
		vim.notify("TaskAnnotate must run from code buffer", vim.log.levels.WARN)
		return
	end

	local root = find_git_root()
	if not root then
		vim.notify("No git root found for current buffer", vim.log.levels.ERROR)
		return
	end

	local code_ref, err = code_ref_for_range(bufnr, root, opts.line1, opts.line2)
	if not code_ref then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	resolve_annotation_text(opts, function(text)
		if not text or text == "" then return end

		local path = ensure_task_file(root)
		append_task_line(path, string.format("- [ ] %s %s", text, code_ref))
		vim.notify("Task note added", vim.log.levels.INFO)
	end)
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

local function jump_to_code()
	local task_win = vim.api.nvim_get_current_win()
	local line = vim.api.nvim_get_current_line()
	local ref = parse_code_ref(line)
	local root = task_root(0)

	if not ref or not root then
		vim.notify("No code link on current task", vim.log.levels.WARN)
		return
	end

	local target = root .. "/" .. ref.rel_path
	if vim.fn.filereadable(target) == 0 then
		vim.notify("Linked file missing: " .. ref.rel_path, vim.log.levels.ERROR)
		return
	end

	local target_win = task_win
	local origin_win = vim.w.task_origin_win
	if origin_win and vim.api.nvim_win_is_valid(origin_win) then
		target_win = origin_win
	end

	if target_win ~= task_win then
		vim.api.nvim_set_current_win(target_win)
	end

	vim.cmd("edit " .. vim.fn.fnameescape(target))
	vim.api.nvim_win_set_cursor(0, { ref.start_line, 0 })

	if target_win ~= task_win and vim.api.nvim_win_is_valid(task_win) and is_float_win(task_win) then
		vim.api.nvim_win_close(task_win, true)
	end
end

----------------------------------------------------------------------
-- highlights
----------------------------------------------------------------------

local function setup_highlights()
	local normal = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
	local title = vim.api.nvim_get_hl(0, { name = "FloatTitle", link = false })
	local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
	local title_bg = 0x87E2FC
	local title_fg = normal.bg or 0x000000
	vim.api.nvim_set_hl(0, "TaskDone", { link = "Comment" })
	vim.api.nvim_set_hl(0, "TaskWip", { link = "WarningMsg" })
	vim.api.nvim_set_hl(0, "TaskCodeLink", { link = "Directory" })
	vim.api.nvim_set_hl(0, "TaskFloatTitle", { fg = title_fg, bg = title_bg, bold = true })
end

refresh_highlights = function(bufnr)
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

		local ref = parse_code_ref(line)
		if ref then
			vim.api.nvim_buf_add_highlight(bufnr, ns, "TaskCodeLink", i - 1, ref.match_start - 1, ref.match_end)
		end
	end
end

----------------------------------------------------------------------
-- open / create (EXPORTED)
----------------------------------------------------------------------

function M.open_task_file()
	local root = find_git_root() or vim.fn.getcwd()
	local path = ensure_task_file(root)
	local origin_win = vim.api.nvim_get_current_win()
	local bufnr = vim.fn.bufadd(path)

	vim.fn.bufload(bufnr)
	vim.bo[bufnr].bufhidden = "hide"

	local win = vim.api.nvim_open_win(bufnr, true, float_layout(root))
	vim.w.task_origin_win = origin_win
	focus_first_task_line(win, bufnr)

	return win
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
	vim.keymap.set("n", "q", ":wq<Return>", { buffer = bufnr, silent = true })
	vim.keymap.set("n", "<Esc>", ":wq<Return>", { buffer = bufnr, silent = true })

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

	if k.jump then
		vim.keymap.set("n", k.jump, jump_to_code, vim.tbl_extend("force", opts, { desc = "Task: jump to code" }))
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

	if config.keys.annotate then
		vim.keymap.set("n", config.keys.annotate, "<Cmd>TaskAnnotate<CR>", { silent = true, desc = "Task: annotate code" })
		vim.keymap.set("x", config.keys.annotate, ":TaskAnnotate<CR>", { silent = true, desc = "Task: annotate selection" })
	end

	-- user command
	vim.api.nvim_create_user_command("Task", function()
		M.open_task_file()
	end, {})

	vim.api.nvim_create_user_command("TaskAnnotate", function(opts)
		annotate_code({
			bufnr = 0,
			line1 = opts.line1,
			line2 = opts.line2,
			text = opts.args,
		})
	end, { nargs = "*", range = true, desc = "Add task linked to current code" })

	vim.api.nvim_create_user_command("TaskJump", jump_to_code, { desc = "Jump from task to linked code" })

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
