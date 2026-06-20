-- Minimal task manager for .task.md files.
-- One file per git project: a title line and a flat checkbox list.

local M = {}

local config = {
	filename = ".task.md",
	-- optional: override where per-project task files are stored
	-- default: ~/.local/share/shadow-task
	storage_dir = nil,
	keys = {
		open     = "<C-0>",
		annotate = "<leader>ta",
		toggle   = "<CR>",
		cycle    = "<Tab>",
		add      = "o",
		above    = "O",
		delete   = "dd",
		jump     = "gd",
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

-- project_hash removed: use project_name(root) for storage directory names
local function project_hash(root)
	-- kept for compatibility but returns the project name (no hashing)
	return project_name(root)
end

local function storage_root_dir()
	if config.storage_dir and config.storage_dir ~= "" then
		return vim.fn.expand(config.storage_dir)
	end
	return vim.fn.expand('~/.local/share/shadow-task')
end

local function storage_root(root)
	-- use project name rather than a hash so stored projects are discoverable
	return storage_root_dir() .. '/' .. project_name(root)
end

local function storage_filename()
	-- store without leading dot to avoid cluttering projects (e.g. task.md)
	local s = config.filename:gsub('^%.', '')
	return s
end

local function storage_task_path(root)
	return storage_root(root) .. '/' .. storage_filename()
end

local function original_task_path(root)
	return root .. '/' .. config.filename
end

local function task_path(root)
	-- store per-project task file inside Neovim data (e.g. ~/.local/share/nvim/shadow-task/<hash>/.task.md)
	return storage_task_path(root)
end

local function is_task_buf(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr or 0)
	if name == "" then return false end
	if name:sub(- #config.filename) == config.filename then return true end
	local sfn = storage_filename()
	if name:sub(- #sfn) == sfn then return true end
	return false
end

local function task_root(bufnr)
	bufnr = bufnr or 0
	-- prefer explicit project root stored on buffer
	local ok, proj = pcall(vim.api.nvim_buf_get_var, bufnr, 'task_project_root')
	if ok and proj and proj ~= vim.NIL then
		return proj
	end

	local path = vim.api.nvim_buf_get_name(bufnr)
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
local float_windows = {}

local function next_state(current)
	for i, s in ipairs(cycle_states) do
		if s == current then
			return cycle_states[(i % #cycle_states) + 1]
		end
	end
	return " "
end

local function ensure_task_file(root)
	local orig = original_task_path(root)
	local storage = task_path(root)

	-- if project contains a .task.md, move it into storage (unless storage already has one)
	if vim.fn.filereadable(orig) == 1 then
		-- ensure storage dir exists
		vim.fn.mkdir(storage_root(root), "p")
		if vim.fn.filereadable(storage) == 0 then
			-- rename (move) original into storage
			pcall(vim.fn.rename, orig, storage)
		else
			-- storage already has file; remove original to avoid committing
			pcall(vim.fn.delete, orig)
		end
	end

	-- ensure storage file exists
	if vim.fn.filereadable(storage) == 0 then
		vim.fn.mkdir(storage_root(root), "p")
		-- record original project root for later resolution (so listing/jump can work)
		local meta = storage_root(root) .. '/.project_root'
		pcall(function()
			local mf = io.open(meta, "w")
			if mf then mf:write(root .. "\n") mf:close() end
		end)
		local f = io.open(storage, "w")
		if f then
			f:write("\n- [ ] \n")
			f:close()
		end
	end

	-- ensure metadata exists even if original was moved in earlier branch
	pcall(function()
		local meta = storage_root(root) .. '/.project_root'
		if vim.fn.filereadable(meta) == 0 then
			local mf = io.open(meta, "w")
			if mf then mf:write(root .. "\n") mf:close() end
		end
	end)

	return storage
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

	vim.cmd("edit " .. vim.fn.fnameescape(path))
	-- attach project root to buffer so task logic can resolve code links
	local bufnr = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_set_var, bufnr, 'task_project_root', root)
	focus_first_task_line(0, 0)
end

function M.open_task_float()
	local root = find_git_root() or vim.fn.getcwd()

	-- toggle: if a float for this project is open, close it
	local existing = float_windows[root]
	if existing then
		if vim.api.nvim_win_is_valid(existing) then
			vim.api.nvim_win_close(existing, true)
		else
			float_windows[root] = nil
		end
		return
	end

	local path = ensure_task_file(root)
	local origin_win = vim.api.nvim_get_current_win()
	local bufnr = vim.fn.bufadd(path)

	vim.fn.bufload(bufnr)
	vim.bo[bufnr].bufhidden = "hide"
	-- attach project root to buffer so task logic can resolve code links
	pcall(vim.api.nvim_buf_set_var, bufnr, 'task_project_root', root)

	local win = vim.api.nvim_open_win(bufnr, true, float_layout(root))
	vim.w.task_origin_win = origin_win
	focus_first_task_line(win, bufnr)

	-- remember mapping so subsequent calls toggle
	float_windows[root] = win

	-- clean mapping when window closes
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(ev)
			local closed = tonumber(ev.match)
			if float_windows[root] == closed then
				float_windows[root] = nil
			end
		end,
	})

	return win
end

-- open task float for an arbitrary project root (used by TaskProjects)
function M.open_task_float_for_root(root)
	if not root or root == '' then return nil end

	-- toggle: if a float for this project is open, close it
	local existing = float_windows[root]
	if existing then
		if vim.api.nvim_win_is_valid(existing) then
			vim.api.nvim_win_close(existing, true)
		else
			float_windows[root] = nil
		end
		return
	end

	-- ensure storage exists for this root
	local path = ensure_task_file(root)
	local origin_win = vim.api.nvim_get_current_win()
	local bufnr = vim.fn.bufadd(path)

	vim.fn.bufload(bufnr)
	vim.bo[bufnr].bufhidden = "hide"
	-- attach the provided project root so code links resolve
	pcall(vim.api.nvim_buf_set_var, bufnr, 'task_project_root', root)

	local win = vim.api.nvim_open_win(bufnr, true, float_layout(root))
	vim.w.task_origin_win = origin_win
	focus_first_task_line(win, bufnr)

	-- remember mapping so subsequent calls toggle
	float_windows[root] = win

	-- clean mapping when window closes
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(ev)
			local closed = tonumber(ev.match)
			if float_windows[root] == closed then
				float_windows[root] = nil
			end
		end,
	})

	return win
end

--- Project listing and management
local function list_projects()
	local dir = storage_root_dir()
	if vim.fn.isdirectory(dir) == 0 then return {} end
	local entries = vim.fn.readdir(dir)
	if type(entries) ~= 'table' then return {} end
	table.sort(entries)
	return entries
end

local function project_storage_root_by_name(name)
	return storage_root_dir() .. '/' .. name
end

local function project_task_file_by_name(name)
	return project_storage_root_by_name(name) .. '/' .. storage_filename()
end

local function project_meta_root(name)
	local meta = project_storage_root_by_name(name) .. '/.project_root'
	if vim.fn.filereadable(meta) == 0 then return nil end
	local lines = vim.fn.readfile(meta)
	return lines and lines[1] or nil
end

local function show_projects()
	local projects = list_projects()
	if #projects == 0 then
		vim.notify("No projects with tasks found in " .. storage_root_dir(), vim.log.levels.INFO)
		return
	end

	vim.ui.select(projects, { prompt = "Select project" }, function(choice)
		if not choice then return end

		local actions = { "Open tasks", "Delete tasks", "Show path", "Cancel" }
		vim.ui.select(actions, { prompt = "Action for " .. choice }, function(action)
			if not action or action == "Cancel" then return end
			local path = project_task_file_by_name(choice)
			if action == "Open tasks" then
				local real_root = project_meta_root(choice)
				-- prefer opening float attached to original project root when available
				if real_root and vim.fn.isdirectory(real_root) == 1 then
					M.open_task_float_for_root(real_root)
					return
				end
				-- fallback: open stored task file in a floating window
				if vim.fn.filereadable(path) == 0 then
					vim.notify("Task file missing for " .. choice, vim.log.levels.ERROR)
					return
				end
				local bufnr = vim.fn.bufadd(path)
				vim.fn.bufload(bufnr)
				vim.bo[bufnr].bufhidden = "hide"
				-- attach storage-based project root so jumps do something sensible
				pcall(vim.api.nvim_buf_set_var, bufnr, 'task_project_root', project_storage_root_by_name(choice))
				local win = vim.api.nvim_open_win(bufnr, true, float_layout(project_storage_root_by_name(choice)))
				vim.w.task_origin_win = vim.api.nvim_get_current_win()
				focus_first_task_line(win, bufnr)
				float_windows[project_storage_root_by_name(choice)] = win
				vim.api.nvim_create_autocmd("WinClosed", {
					callback = function(ev)
						local closed = tonumber(ev.match)
						if float_windows[project_storage_root_by_name(choice)] == closed then
							float_windows[project_storage_root_by_name(choice)] = nil
						end
					end,
				})
			elseif action == "Delete tasks" then
				vim.ui.select({"Yes", "No"}, { prompt = "Delete project tasks for " .. choice .. "? (irreversible)" }, function(confirm)
					if confirm ~= "Yes" then return end
					local dir = project_storage_root_by_name(choice)
					if vim.fn.isdirectory(dir) == 0 then
						vim.notify("Project storage not found: " .. dir, vim.log.levels.WARN)
						return
					end
					-- remove recursively
					local ok, err = pcall(function() vim.fn.delete(dir, "rf") end)
					if not ok then
						vim.notify("Failed to delete: " .. tostring(err), vim.log.levels.ERROR)
					else
						vim.notify("Deleted tasks for " .. choice, vim.log.levels.INFO)
					end
				end)
			elseif action == "Show path" then
				local real_root = project_meta_root(choice)
				if real_root then
					vim.notify("Original project root: " .. real_root, vim.log.levels.INFO)
				else
					vim.notify("Stored task path: " .. path, vim.log.levels.INFO)
				end
			end
		end)
	end)
end

---------------------------------------------------------------------
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
		M.open_task_float()
	end, { silent = true, desc = "Task: open float" })

	if config.keys.annotate then
		vim.keymap.set("n", config.keys.annotate, "<Cmd>TaskAnnotate<CR>", { silent = true, desc = "Task: annotate code" })
		vim.keymap.set("x", config.keys.annotate, ":TaskAnnotate<CR>", { silent = true, desc = "Task: annotate selection" })
	end

	-- user command
	vim.api.nvim_create_user_command("Task", function()
		M.open_task_file()
	end, { desc = "Open task file in current window" })

	vim.api.nvim_create_user_command("TaskFloat", function()
		M.open_task_float()
	end, { desc = "Open task file in floating window" })

	-- list stored projects and manage their task files
	vim.api.nvim_create_user_command("TaskProjects", function()
		show_projects()
	end, { desc = "List stored projects and open/delete task files" })

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
		pattern = { "*/" .. config.filename, "*/" .. storage_filename(), config.filename, storage_filename() },
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
