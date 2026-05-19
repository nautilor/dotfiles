local M = {}

local states = {}
local build_timers = {}
local mapstruct_cache = {}
local command_group = vim.api.nvim_create_augroup("shadow-java", { clear = true })
local buffer_group = vim.api.nvim_create_augroup("shadow-java-buffer", { clear = true })

local float = {
	width = 0.82,
	height = 0.75,
	border = "solid",
}

local debug = {
	host = "127.0.0.1",
	port = 5005,
}

-- Determine the project root by looking for common build files or using a buffer-local override
local function root_dir()
	local current = vim.api.nvim_get_current_buf()
	local console_root = vim.b[current].shadow_java_root
	if console_root and console_root ~= "" then
		return console_root
	end

	local name = vim.api.nvim_buf_get_name(0)
	return vim.fs.root(name ~= "" and name or vim.fn.getcwd(),
				{ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" })
			or vim.fn.getcwd()
end

local function file_exists(path)
	return vim.uv.fs_stat(path) ~= nil
end

-- Detect if the project is a Java project by looking for common build files
local function is_java_project(root)
	return file_exists(root .. "/pom.xml")
			or file_exists(root .. "/build.gradle")
			or file_exists(root .. "/build.gradle.kts")
			or file_exists(root .. "/settings.gradle")
			or file_exists(root .. "/settings.gradle.kts")
end

-- Read a file's content safely, returning an empty string on failure
local function read_file(path)
	local ok, data = pcall(vim.fn.readfile, path)
	if not ok or not data then
		return ""
	end
	return table.concat(data, "\n")
end

-- Check if the project uses MapStruct by looking for its mention in build files, with caching
local function project_has_mapstruct(root)
	if mapstruct_cache[root] ~= nil then
		return mapstruct_cache[root]
	end

	for _, file in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
		local path = root .. "/" .. file
		if file_exists(path) and read_file(path):find("mapstruct", 1, true) then
			mapstruct_cache[root] = true
			return true
		end
	end

	mapstruct_cache[root] = false
	return false
end

-- Build the command to run the project based on detected build tool (Maven or Gradle)
local function build_tool(root)
	local gradle_files = {
		root .. "/gradlew",
		root .. "/build.gradle",
		root .. "/build.gradle.kts",
		root .. "/settings.gradle",
		root .. "/settings.gradle.kts",
	}

	for _, path in ipairs(gradle_files) do
		if file_exists(path) then
			return {
				kind = "gradle",
				cmd = file_exists(root .. "/gradlew") and "./gradlew" or "gradle",
			}
		end
	end

	return {
		kind = "maven",
		cmd = file_exists(root .. "/mvnw") and "./mvnw" or "mvn",
	}
end

-- Detect if the project uses Spring Boot or Quarkus by looking for their mention in build files
local function detect_framework(root)
	for _, file in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
		local path = root .. "/" .. file
		if file_exists(path) then
			local content = read_file(path)
			if content:find("quarkus", 1, true) then
				return "quarkus"
			end
			if content:find("spring%-boot") or content:find("org.springframework.boot", 1, true) then
				return "spring"
			end
		end
	end

	return nil
end

-- Find profile files in the project root that match common Spring Boot naming conventions
local function profile_files(root)
	return vim.fs.find(function(name)
		return name:match("^application%-.+%.properties$")
				or name:match("^application%-.+%.ya?ml$")
	end, {
		path = root,
		limit = 100,
		type = "file",
	})
end

-- List available profiles by checking current state, scanning for profile files, and including common defaults
local function list_profiles(root)
	local seen = {}
	local items = {}

	local function add(profile)
		if profile and profile ~= "" and not seen[profile] then
			seen[profile] = true
			table.insert(items, profile)
		end
	end

	add((states[root] or {}).profile)

	for _, path in ipairs(profile_files(root)) do
		local name = vim.fs.basename(path)
		local profile = name:match("^application%-(.+)%.properties$")
				or name:match("^application%-(.+)%.ya?ml$")
		add(profile)
	end

	for _, profile in ipairs({ "dev", "local" }) do
		add(profile)
	end

	table.insert(items, 1, "none")
	table.insert(items, "custom")

	return items
end

-- Open a floating window centered on the screen with the given buffer and title
local function open_float(bufnr, title)
	local width = math.max(80, math.floor(vim.o.columns * float.width))
	local height = math.max(12, math.floor(vim.o.lines * float.height))

	return vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		style = "minimal",
		border = float.border,
		title = " " .. title .. " ",
		title_pos = "center",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
	})
end

-- Set up keymaps for the console buffer to allow toggling it from both normal and terminal mode, and store the project root in buffer-local state
local function set_console_buffer_keymaps(bufnr, root)
	local opts = { buffer = bufnr, silent = true, desc = "Java: toggle console" }
	vim.b[bufnr].shadow_java_root = root
	vim.keymap.set("n", "<leader>jl", "<Cmd>JavaToggleConsole<CR>", opts)
	vim.keymap.set("t", "<leader>jl", [[<C-\><C-n><Cmd>JavaToggleConsole<CR>]], opts)
end

local function project_state(root)
	states[root] = states[root] or {}
	return states[root]
end

local function job_running(job_id)
	return job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function toggle_console()
	local root = root_dir()
	local state = states[root]

	if state and state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
		if state.winid and vim.api.nvim_win_is_valid(state.winid) then
			vim.api.nvim_win_close(state.winid, true)
			state.winid = nil
			return
		end

		state.winid = open_float(state.bufnr, state.title or "Java Console")
		vim.cmd("startinsert")
		return
	end

	local ok, java = pcall(require, "java")
	if ok then
		java.runner.built_in.toggle_logs()
	end
end

local function stop_custom(root)
	local state = states[root]
	if state and job_running(state.job_id) then
		vim.fn.jobstop(state.job_id)
		state.job_id = nil
	end
	if state then
		state.debug_host = nil
		state.debug_port = nil
	end
end

local function stop_runner()
	local root = root_dir()
	stop_custom(root)

	local ok, java = pcall(require, "java")
	if ok then
		java.runner.built_in.stop_app()
	end
end

local function run_in_terminal(root, title, cmd)
	local state = project_state(root)
	stop_custom(root)

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.bo[bufnr].bufhidden = "hide"
	vim.bo[bufnr].swapfile = false
	vim.api.nvim_buf_set_name(bufnr, ("java://%s/%s"):format(vim.fs.basename(root), title:gsub("%s+", "-"):lower()))
	set_console_buffer_keymaps(bufnr, root)

	local winid = state.winid and vim.api.nvim_win_is_valid(state.winid) and state.winid or open_float(bufnr, title)
	if vim.api.nvim_win_get_buf(winid) ~= bufnr then
		vim.api.nvim_win_set_buf(winid, bufnr)
	end

	state.bufnr = bufnr
	state.winid = winid
	state.title = title
	state.job_id = vim.fn.termopen(cmd, {
		cwd = root,
		on_exit = function(job_id, code)
			vim.schedule(function()
				if state.job_id == job_id then
					state.job_id = nil
					state.debug_host = nil
					state.debug_port = nil
				end
				local level = code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
				vim.notify(title .. " exited (" .. code .. ")", level)
			end)
		end,
	})

	vim.cmd("startinsert")
end

local function spring_gradle_args(profile, extra_args)
	local args = {}
	if profile and profile ~= "" then
		table.insert(args, "--spring.profiles.active=" .. profile)
	end
	for _, arg in ipairs(extra_args or {}) do
		table.insert(args, arg)
	end
	return args
end

local function shell_args(arg_string)
	if not arg_string or arg_string == "" then
		return {}
	end
	return vim.split(arg_string, "%s+", { trimempty = true })
end

local function debug_agent_arg()
	return "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:" .. debug.port
end

local function build_run_command(kind, tool, profile, arg_string, debug_mode)
	local extra_args = shell_args(arg_string)

	if kind == "spring" then
		if tool.kind == "maven" then
			local cmd = { tool.cmd, "spring-boot:run" }
			if profile and profile ~= "" then
				table.insert(cmd, "-Dspring-boot.run.profiles=" .. profile)
			end
			if debug_mode then
				table.insert(cmd, "-Dspring-boot.run.jvmArguments=" .. debug_agent_arg())
			end
			return cmd, "Spring Boot"
		end

		local cmd = { tool.cmd, "bootRun" }
		if debug_mode then
			table.insert(cmd, "--debug-jvm")
		end
		local args = spring_gradle_args(profile, extra_args)
		if #args > 0 then
			table.insert(cmd, "--args=" .. table.concat(args, " "))
		end
		return cmd, "Spring Boot"
	end

	if kind == "quarkus" then
		local goal = tool.kind == "maven" and "quarkus:dev" or "quarkusDev"
		local cmd = { tool.cmd, goal }
		if profile and profile ~= "" then
			table.insert(cmd, "-Dquarkus.profile=" .. profile)
		end
		if debug_mode then
			table.insert(cmd, "-Ddebug=" .. debug.port)
		end
		for _, arg in ipairs(extra_args) do
			table.insert(cmd, arg)
		end
		return cmd, "Quarkus"
	end

	local cmd = { tool.cmd, "test" }
	if profile and profile ~= "" then
		table.insert(cmd, "-Dspring.profiles.active=" .. profile)
	end
	for _, arg in ipairs(extra_args) do
		table.insert(cmd, arg)
	end
	return cmd, "Tests"
end

local function profile_choices(root)
	local items = {}

	local function add(label, profile, custom)
		table.insert(items, {
			label = label,
			profile = profile,
			custom = custom or false,
		})
	end

	for _, profile in ipairs(list_profiles(root)) do
		if profile == "custom" then
			add("custom", nil, true)
		else
			local resolved = profile ~= "none" and profile or nil
			add(profile, resolved, false)
		end
	end

	return items
end

local function with_profile(root, cb)
	local options = profile_choices(root)
	vim.ui.select(options, {
		prompt = "Java profile",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end

		local function finish(profile)
			project_state(root).profile = profile
			cb(profile)
		end

		if choice.custom then
			vim.ui.input({ prompt = "Profile: ", default = (states[root] or {}).profile or "" }, function(input)
				if input == nil then
					return
				end

				local profile = input ~= "" and input or nil
				finish(profile)
			end)
			return
		end

		finish(choice.profile)
	end)
end

local function with_run_mode(opts, cb)
	opts = opts or {}
	if not opts.allow_debug then
		cb(false)
		return
	end

	vim.ui.select({ "run", "debug" }, { prompt = "Java run mode" }, function(choice)
		if not choice then
			return
		end

		cb(choice == "debug")
	end)
end

local function run_framework(kind, opts)
	local root = root_dir()
	local tool = build_tool(root)
	opts = opts or {}

	with_run_mode(opts, function(debug_mode)
		with_profile(root, function(profile)
			local cmd, title = build_run_command(kind, tool, profile, opts.args, debug_mode)
			local state = project_state(root)
			state.debug_host = debug_mode and debug.host or nil
			state.debug_port = debug_mode and debug.port or nil
			local suffix = profile and (" [" .. profile .. "]") or ""
			if debug_mode then
				suffix = suffix .. " [debug]"
			end
			run_in_terminal(root, title .. suffix, cmd)
		end)
	end)
end

local function run_main(opts)
	local root = root_dir()
	local framework = detect_framework(root)

	if framework == "spring" or framework == "quarkus" then
		run_framework(framework, vim.tbl_extend("force", opts or {}, { allow_debug = true }))
		return
	end

	local ok, java = pcall(require, "java")
	if not ok then
		vim.notify("nvim-java not available", vim.log.levels.ERROR)
		return
	end

	java.runner.built_in.run_app(shell_args(opts.args))
end

local function build_workspace()
	local ok, java = pcall(require, "java")
	if not ok or not java.build or not java.build.build_workspace then
		vim.notify("Java workspace build API unavailable", vim.log.levels.ERROR)
		return
	end

	java.build.build_workspace()
end

local function refresh_mappers()
	build_workspace()
end

local function stop_timer(root)
	local timer = build_timers[root]
	if timer then
		timer:stop()
		timer:close()
		build_timers[root] = nil
	end
end

local function schedule_mapstruct_refresh(path)
	local root = vim.fs.root(path, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" })
	if not root or not project_has_mapstruct(root) then
		return
	end

	stop_timer(root)
	local timer = assert(vim.uv.new_timer())
	build_timers[root] = timer
	timer:start(350, 0, function()
		stop_timer(root)
		vim.schedule(function()
			refresh_mappers()
		end)
	end)
end

local function source_root_for_dir(dir)
	local normalized = vim.fs.normalize(dir)
	return normalized:match("^(.*[/\\]src[/\\][^/\\]+[/\\]java)")
			or normalized:match("^(.*[/\\]java)")
end

local function package_name_for_dir(dir)
	local source_root = source_root_for_dir(dir)
	if not source_root then
		return nil
	end

	local rel = dir:sub(#source_root + 2)
	if rel == "" then
		return nil
	end

	return rel:gsub("[/\\]+", ".")
end

local function java_type_stub(kind, name, package_name)
	local lines = {}
	if package_name and package_name ~= "" then
		table.insert(lines, "package " .. package_name .. ";")
		table.insert(lines, "")
	end

	if kind == "class" then
		vim.list_extend(lines, {
			"public class " .. name .. " {",
			"",
			"}",
		})
	elseif kind == "enum" then
		vim.list_extend(lines, {
			"public enum " .. name .. " {",
			"",
			"}",
		})
	elseif kind == "interface" then
		vim.list_extend(lines, {
			"public interface " .. name .. " {",
			"",
			"}",
		})
	else
		vim.list_extend(lines, {
			"public @interface " .. name .. " {",
			"",
			"}",
		})
	end

	return lines
end

local function explorer_update(picker, path)
	local Tree = require("snacks.explorer.tree")
	local actions = require("snacks.explorer.actions")
	local dir = vim.fs.dirname(path)
	Tree:open(dir)
	Tree:refresh(dir)
	actions.update(picker, { target = path })
end

local function create_simple_explorer_path(picker)
	require("snacks.explorer.actions").actions.explorer_add(picker)
end

local function create_java_type_file(picker, kind)
	local dir = picker:dir()
	vim.ui.input({ prompt = "Java " .. kind .. " name: " }, function(name)
		if not name or name:match("^%s*$") then
			return
		end

		name = vim.trim(name)
		local path = vim.fs.normalize(dir .. "/" .. name .. ".java")
		if file_exists(path) then
			vim.notify("File already exists: " .. path, vim.log.levels.WARN)
			return
		end

		vim.fn.mkdir(vim.fs.dirname(path), "p")
		local lines = java_type_stub(kind, name, package_name_for_dir(dir))
		vim.fn.writefile(lines, path)
		explorer_update(picker, path)
	end)
end

function M.explorer_add(picker)
	local dir = picker:dir()
	local root = vim.fs.root(dir, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" })
	if not root or not is_java_project(root) then
		create_simple_explorer_path(picker)
		return
	end

	vim.ui.select({
		"class",
		"enum",
		"interface",
		"annotation",
		"simple file",
	}, {
		prompt = "Java file type",
	}, function(choice)
		if not choice then
			return
		end

		if choice == "simple file" then
			create_simple_explorer_path(picker)
			return
		end

		create_java_type_file(picker, choice)
	end)
end

local function select_profile()
	with_profile(root_dir(), function(profile)
		local msg = profile and ("Java profile: " .. profile) or "Java profile cleared"
		vim.notify(msg, vim.log.levels.INFO)
	end)
end

local function attach_debugger()
	local ok, dap = pcall(require, "dap")
	if not ok then
		vim.notify("nvim-dap not available", vim.log.levels.ERROR)
		return
	end

	local state = project_state(root_dir())
	dap.run({
		type = "java_attach",
		request = "attach",
		name = "Debug (Attach) - Java",
		hostName = state.debug_host or debug.host,
		port = state.debug_port or debug.port,
	})
end

local function map(bufnr, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

local function setup_commands()
	vim.api.nvim_create_user_command("JavaRun", function(opts)
		run_main(opts)
	end, { nargs = "*", desc = "Run Java app, Spring Boot, or Quarkus dev mode" })

	vim.api.nvim_create_user_command("JavaRunSpring", function(opts)
		run_framework("spring", opts)
	end, { nargs = "*", desc = "Run Spring Boot with selected profile" })

	vim.api.nvim_create_user_command("JavaRunQuarkus", function(opts)
		run_framework("quarkus", opts)
	end, { nargs = "*", desc = "Run Quarkus dev mode with selected profile" })

	vim.api.nvim_create_user_command("JavaRunTests", function(opts)
		run_framework("tests", opts)
	end, { nargs = "*", desc = "Run project test suite with selected profile" })

	vim.api.nvim_create_user_command("JavaToggleConsole", toggle_console,
		{ desc = "Toggle Java floating console" })
	vim.api.nvim_create_user_command("JavaStop", stop_runner, { desc = "Stop Java runner" })
	vim.api.nvim_create_user_command("JavaSelectProfile", select_profile, { desc = "Select Java profile" })
	vim.api.nvim_create_user_command("JavaAttachDebugger", attach_debugger, { desc = "Attach Java debugger" })
	vim.api.nvim_create_user_command("JavaDebugMain", attach_debugger, { desc = "Attach Java debugger" })
	vim.api.nvim_create_user_command("JavaBuildWorkspace", build_workspace, { desc = "Build Java workspace" })
	vim.api.nvim_create_user_command("JavaRefreshMappers", refresh_mappers,
		{ desc = "Rebuild Java workspace to refresh generated mappers" })
end

local function setup_java_buffer(bufnr)
	map(bufnr, "<leader>jr", "<Cmd>JavaRun<CR>", "Java: run app")
	map(bufnr, "<leader>jq", "<Cmd>JavaRunQuarkus<CR>", "Java: run Quarkus")
	map(bufnr, "<leader>jb", "<Cmd>JavaRunSpring<CR>", "Java: run Spring Boot")
	map(bufnr, "<leader>jp", "<Cmd>JavaSelectProfile<CR>", "Java: select profile")
	map(bufnr, "<leader>jl", "<Cmd>JavaToggleConsole<CR>", "Java: toggle console")
	map(bufnr, "<leader>js", "<Cmd>JavaStop<CR>", "Java: stop runner")
	map(bufnr, "<leader>jt", "<Cmd>JavaTestRunCurrentMethod<CR>", "Java: run test method")
	map(bufnr, "<leader>jT", "<Cmd>JavaTestRunCurrentClass<CR>", "Java: run test class")
	map(bufnr, "<leader>ja", "<Cmd>JavaTestRunAllTests<CR>", "Java: run all tests")
	map(bufnr, "<leader>dt", "<Cmd>JavaTestDebugCurrentMethod<CR>", "Debug: test method")
	map(bufnr, "<leader>da", "<Cmd>JavaAttachDebugger<CR>", "Debug: attach Java")
	map(bufnr, "<leader>jm", "<Cmd>JavaRefreshMappers<CR>", "Java: refresh mappers")
	map(bufnr, "<leader>jo", "<Cmd>JavaTestViewLastReport<CR>", "Java: test report")
end

function M.setup()
	if vim.g.shadow_java_setup then
		return
	end
	vim.g.shadow_java_setup = true

	setup_commands()

	vim.api.nvim_create_autocmd("FileType", {
		group = buffer_group,
		pattern = "java",
		callback = function(event)
			setup_java_buffer(event.buf)
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		group = command_group,
		callback = function()
			for _, state in pairs(states) do
				if state.winid and vim.api.nvim_win_is_valid(state.winid) and state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
					local title = state.title or "Java Console"
					vim.api.nvim_win_set_config(state.winid, vim.tbl_extend("force", vim.api.nvim_win_get_config(state.winid), {
						relative = "editor",
						row = math.floor((vim.o.lines - math.max(12, math.floor(vim.o.lines * float.height))) / 2),
						col = math.floor((vim.o.columns - math.max(80, math.floor(vim.o.columns * float.width))) / 2),
						width = math.max(80, math.floor(vim.o.columns * float.width)),
						height = math.max(12, math.floor(vim.o.lines * float.height)),
						title = " " .. title .. " ",
					}))
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = command_group,
		pattern = { "*.java", "pom.xml", "build.gradle", "build.gradle.kts" },
		callback = function(event)
			schedule_mapstruct_refresh(event.match)
		end,
	})
end

return M
